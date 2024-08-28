import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApproveScreen extends StatefulWidget {
  final Map<String, String?> originalFiles;

  const ApproveScreen({
    required this.originalFiles,
    Key? key,
  }) : super(key: key);

  @override
  _ApproveScreenState createState() => _ApproveScreenState();
}

class _ApproveScreenState extends State<ApproveScreen> {
  String? _selectedManager;
  final Map<String, TextEditingController> _controllers = {}; // Quản lý TextEditingController
  final Map<String, int?> quantities = {}; // Lưu trữ số lượng nhập từ người dùng
  final Map<String, String?> errorMessages = {}; // Lưu trữ thông báo lỗi riêng cho từng ô
  String? managerErrorMessage; // Lưu trữ thông báo lỗi cho người soát xét

  @override
  void initState() {
    super.initState();
    // Khởi tạo TextEditingController cho mỗi mục
    widget.originalFiles.forEach((key, value) {
      _controllers[key] = TextEditingController(text: value);
    });
  }

  @override
  void dispose() {
    // Hủy các TextEditingController để tránh rò rỉ bộ nhớ
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset).add(const EdgeInsets.all(16.0)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Phê duyệt hồ sơ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...widget.originalFiles.entries.map((entry) {
              final key = entry.key;
              final controller = _controllers[key]!;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('$key', style: const TextStyle(fontSize: 16)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              labelText: 'Số lượng biên bản gốc',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              // Kiểm tra đầu vào và lưu trữ số lượng nếu hợp lệ
                              final parsedValue = int.tryParse(value);
                              quantities[key] = parsedValue;
                              if (parsedValue == null || parsedValue <= 0) {
                                errorMessages[key] = 'Số lượng biên bản duyệt không phù hợp';
                              } else if (parsedValue > (int.tryParse(widget.originalFiles[key]!) ?? 0)) {
                                errorMessages[key] = 'Số lượng biên bản duyệt lớn hơn số lượng gốc';
                              } else {
                                errorMessages.remove(key); // Xóa thông báo lỗi nếu hợp lệ
                              }
                              setState(() {}); // Cập nhật giao diện
                            },
                          ),
                        ),
                      ],
                    ),
                    if (errorMessages[key] != null) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        errorMessages[key]!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 10),
            const Text('Chọn người soát xét hồ sơ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where('author', isEqualTo: 'manager')
                  .get(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Lỗi: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('Không có người soát xét');
                }

                final List<QueryDocumentSnapshot> managers = snapshot.data!.docs;
                return Column(
                  children: managers.map((manager) {
                    final managerId = manager.id;
                    final managerName = manager['fullName'];
                    return RadioListTile<String>(
                      title: Text(managerName),
                      value: managerId,
                      groupValue: _selectedManager,
                      onChanged: (value) {
                        setState(() {
                          _selectedManager = value;
                          managerErrorMessage = null; // Xóa thông báo lỗi khi người dùng chọn người soát xét
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
            if (managerErrorMessage != null) ...[
              const SizedBox(height: 4.0),
              Text(
                managerErrorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Kiểm tra lỗi số lượng trước khi duyệt
                  if (errorMessages.isNotEmpty) {
                    setState(() {}); // Cập nhật trạng thái để hiển thị thông báo lỗi
                    return;
                  }

                  // Kiểm tra xem đã chọn người soát xét hay chưa
                  if (_selectedManager == null) {
                    setState(() {
                      managerErrorMessage = 'Vui lòng chọn người soát xét';
                    });
                    return;
                  }

                  // Thực hiện logic phê duyệt
                  Navigator.of(context).pop();
                },
                child: const Text('Duyệt Hồ Sơ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
