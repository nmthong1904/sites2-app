import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailScreen extends StatefulWidget {
  final String name;
  final String description;
  final String status;
  final String datetime;
  final Map<String, String?> originalFiles;
  final String nameCreated;
  final String author;

  const ProductDetailScreen({
    required this.name,
    required this.description,
    required this.status,
    required this.datetime,
    required this.originalFiles,
    required this.nameCreated,
    required this.author,
    Key? key,
  }) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedManager;
  String _selectedManagerName = '';

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Đang chờ phê duyệt';
      case 'approved':
        return 'Đang chờ soát xét';
      case 'deployed':
        return 'Đang chờ đóng dấu';
      case 'finished':
        return 'Hồ sơ đã hoàn thiện';
      default:
        return 'Trạng thái không xác định';
    }
  }

  void _showBottomSheet(BuildContext context) {
    final Map<String, int?> quantities = {}; // Lưu trữ số lượng nhập từ người dùng
    String? errorMessage; // Lưu thông báo lỗi

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return GestureDetector(
              onTap: () {
                // Khi người dùng nhấn ra ngoài ô nhập dữ liệu, ẩn bàn phím
                FocusScope.of(context).unfocus();
              },
              child: Container(
                padding: EdgeInsets.only(bottom: bottomInset), // Cung cấp không gian cho bàn phím
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 16.0), // Cung cấp padding chính xác
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Phê duyệt hồ sơ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ...widget.originalFiles.entries.map((entry) {
                          final TextEditingController _controller = TextEditingController(text: entry.value);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text('${entry.key}', style: const TextStyle(fontSize: 16)),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    decoration: const InputDecoration(
                                      labelText: 'Số lượng biên bản gốc',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      quantities[entry.key] = int.tryParse(value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 10),
                        // DropdownButton để chọn người soát xét
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
                            return DropdownButton<String>(
                              hint: Text(
                                _selectedManagerName.isEmpty
                                    ? 'Chọn người soát xét hồ sơ'
                                    : 'Người soát xét: $_selectedManagerName',
                              ),
                              isExpanded: true,
                              value: _selectedManager,
                              items: managers.map((manager) {
                                final managerId = manager.id;
                                final managerName = manager['fullName'];
                                return DropdownMenuItem<String>(
                                  value: managerId,
                                  child: Text(managerName),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                final selectedManager = managers.firstWhere((manager) => manager.id == newValue);
                                setStateDialog(() {
                                  _selectedManager = newValue;
                                  _selectedManagerName = selectedManager['fullName'];
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        if (errorMessage != null) ...[
                          Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 10),
                        ],
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              // Kiểm tra lỗi số lượng
                              bool hasError = false;
                              for (var entry in widget.originalFiles.entries) {
                                final originalQuantity = int.tryParse(entry.value ?? '0') ?? 0;
                                final inputQuantity = quantities[entry.key] ?? 0;
                                if (inputQuantity > originalQuantity) {
                                  hasError = true;
                                  errorMessage = 'Lỗi: Số lượng nhập lớn hơn số lượng gốc';
                                  break;
                                }
                              }

                              if (hasError) {
                                setStateDialog(() {}); // Cập nhật trạng thái để hiển thị thông báo lỗi
                                return;
                              }

                              if (_selectedManager == null) {
                                errorMessage = 'Vui lòng chọn người soát xét';
                                setStateDialog(() {}); // Cập nhật trạng thái để hiển thị thông báo lỗi
                                return;
                              }

                              // Xử lý logic phê duyệt với thông tin đã chọn
                              Navigator.of(context).pop();
                            },
                            child: const Text('Duyệt Hồ Sơ'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết hồ sơ'),
        actions: widget.author == 'user'
            ? [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // Xử lý xóa hồ sơ
              },
            ),
          ),
        ]
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tiêu đề: ${widget.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Mô tả: ${widget.description}\n',
                    style: const TextStyle(fontSize: 16),
                  ),
                  TextSpan(
                    text: 'Trạng thái: ${_getStatusText(widget.status)}\n',
                    style: const TextStyle(fontSize: 16),
                  ),
                  TextSpan(
                    text: 'Ngày tạo hồ sơ: ${widget.datetime}\n',
                    style: const TextStyle(fontSize: 16),
                  ),
                  TextSpan(
                    text: 'Người tạo: ${widget.nameCreated}\n',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              style: const TextStyle(height: 1.5),
            ),
            Text('Biên bản gốc bao gồm', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...widget.originalFiles.entries.map((entry) {
              return Text('${entry.value ?? 'Không có dữ liệu'} ${entry.key}', style: const TextStyle(fontSize: 16));
            }).toList(),
            const SizedBox(height: 10),
            if (widget.author == 'admin') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _showBottomSheet(context);
                    },
                    child: const Text('Phê duyệt hồ sơ'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Xử lý từ chối hồ sơ
                    },
                    child: const Text('Từ chối hồ sơ'),
                  ),
                ],
              ),
            ] else if (widget.author == 'manager') ...[
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Xử lý logic hoàn thành soát xét
                  },
                  child: const Text('Đã Soát Xét Hồ Sơ'),
                ),
              ),
            ] else if (widget.author == 'stamper') ...[
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Xử lý logic đóng dấu
                  },
                  child: const Text('Đã Đóng Dấu Hồ Sơ'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
