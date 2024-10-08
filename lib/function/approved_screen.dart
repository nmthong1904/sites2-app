import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Thêm thư viện intl để định dạng ngày tháng
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sites2app/function/processingdialog_screen.dart';


class ApproveScreen extends StatefulWidget {
  final Map<String, String?> originalFiles;
  final String fileId; // Thêm biến fileId
  final String name; // Thêm biến fileId
  final String createdName; // Thêm biến fileId
  final String approvedName; // Thêm biến fileId

  const ApproveScreen({
    required this.originalFiles,
    required this.fileId, // Thêm biến fileId
    required this.name, // Thêm biến fileId
    required this.createdName, // Thêm biến fileId
    required this.approvedName, // Thêm biến fileId
    Key? key,
  }) : super(key: key);

  @override
  _ApproveScreenState createState() => _ApproveScreenState();
}

class _ApproveScreenState extends State<ApproveScreen> {
  String? _selectedManager;
  String _selectedManagerName = '';
  final Map<String, TextEditingController> _controllers = {}; // Quản lý TextEditingController
  final Map<String, int?> quantities = {}; // Lưu trữ số lượng nhập từ người dùng
  final Map<String, String?> errorMessages = {}; // Lưu trữ thông báo lỗi riêng cho từng ô
  String? managerErrorMessage; // Lưu trữ thông báo lỗi cho người soát xét

  // Thêm TextEditingController để quản lý phần nhận xét
  final TextEditingController _commentController = TextEditingController();

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
    _commentController.dispose(); // Hủy TextEditingController cho nhận xét
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
                              final parsedValue = int.tryParse(value);
                              quantities[key] = parsedValue;
                              if (parsedValue == null || parsedValue < 0) {
                                errorMessages[key] = 'Số lượng biên bản duyệt không phù hợp';
                              } else if (parsedValue > (int.tryParse(widget.originalFiles[key]!) ?? 0)) {
                                errorMessages[key] = 'Số lượng biên bản duyệt lớn hơn số lượng gốc';
                              } else {
                                errorMessages.remove(key);
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
                          _selectedManagerName = managerName;
                          _selectedManager = value;
                          managerErrorMessage = null;
                        });
                      },
                      activeColor: Colors.blue,
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
            const Text('Nhận xét', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Nhập nhận xét của bạn',
                border: OutlineInputBorder(),
              ),
              maxLines: 3, // Đặt số dòng tối đa cho phần nhận xét
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.blue[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(300, 50),
                ),
                onPressed: () async {
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

                  // Hiển thị màn hình xử lý
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const ProcessingdialogScreen();
                    },
                  );

                  // Lấy thời gian hiện tại
                  final approvedTime = DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now());

                  // Tạo map để lưu các file đã được duyệt
                  final approvedFiles = Map<String, String?>.from(widget.originalFiles);
                  quantities.forEach((key, value) {
                    approvedFiles[key] = value.toString(); // Cập nhật số lượng đã duyệt
                  });

                  // Cập nhật vào Firebase Realtime Database
                  await FirebaseDatabase.instance.ref().child('files').child(widget.fileId).update({
                    'approvedtime': approvedTime,
                    'approvedFiles': approvedFiles,
                    'status': 'approved',
                    'deployedName': _selectedManagerName,
                    'comment_admin': _commentController.text, // Thêm nhận xét
                  });
                  // Cập nhật vào Firebase Realtime Database notifications
                  await FirebaseDatabase.instance.ref().child('notifications').child(widget.fileId).update({
                    _selectedManagerName:{
                        'message': 'Có hồ sơ ${widget.name} của ${widget.createdName} cần được kiểm tra vào $approvedTime',
                        'isRead': false,
                    }
                  });
                  // Cập nhật vào Firebase Realtime Database notifications
                  await FirebaseDatabase.instance.ref().child('notifications').child(widget.fileId).update({
                    widget.createdName:{
                      'message': 'Hồ sơ ${widget.name} vừa được ký bởi ${widget.approvedName} vào $approvedTime',
                      'isRead': false,
                    }
                  });

                  // Đợi 2 giây
                  await Future.delayed(const Duration(seconds: 2));

                  // Điều hướng trở về HomeScreen
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text(
                  'Duyệt Hồ Sơ',
                  style: TextStyle(color: Colors.white), // Màu chữ trắng
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
