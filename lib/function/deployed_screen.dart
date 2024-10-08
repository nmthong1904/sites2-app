import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Thêm thư viện intl để định dạng ngày tháng
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sites2app/function/processingdialog_screen.dart';


class DeployedScreen extends StatefulWidget {
  final Map<String, String?> approvedFiles;
  final String fileId; // Thêm biến fileId
  final String name; // Thêm biến fileId
  final String createdName; // Thêm biến fileId
  final String stamperName; // Thêm biến fileId

  const DeployedScreen({
    required this.approvedFiles,
    required this.fileId, // Thêm biến fileId
    required this.name, // Thêm biến fileId
    required this.createdName, // Thêm biến fileId
    required this.stamperName, // Thêm biến fileId
    Key? key,
  }) : super(key: key);

  @override
  _DeployedScreenState createState() => _DeployedScreenState();
}

class _DeployedScreenState extends State<DeployedScreen> {
  String? _selectedStamper;
  String _selectedStamperName = '';
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
    widget.approvedFiles.forEach((key, value) {
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
            ...widget.approvedFiles.entries.map((entry) {
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
                              if (parsedValue == null || parsedValue < 0) {
                                errorMessages[key] = 'Số lượng biên bản kiểm tra không phù hợp';
                              } else if (parsedValue > (int.tryParse(widget.approvedFiles[key]!) ?? 0)) {
                                errorMessages[key] = 'Số lượng biên bản kiểm tra lớn hơn số lượng được phê duyệt';
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
                    const SizedBox(height: 10),
                  ],
                ),
              );
            }).toList(),
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
            const Text('Chọn người đóng dấu hồ sơ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where('author', isEqualTo: 'stamper')
                  .get(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Lỗi: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('Vui lòng chọn người đóng dấu hồ sơ');
                }

                final List<QueryDocumentSnapshot> stampers = snapshot.data!.docs;
                return Column(
                  children: stampers.map((stampers) {
                    final stamperId = stampers.id;
                    final stamperName = stampers['fullName'];
                    return RadioListTile<String>(
                      title: Text(stamperName),
                      value: stamperId,
                      groupValue: _selectedStamper,
                      onChanged: (value) {
                        setState(() {
                          _selectedStamperName = stamperName;
                          _selectedStamper = value;
                          managerErrorMessage = null; // Xóa thông báo lỗi khi người dùng chọn người soát xét
                        });
                      },
                      activeColor: Colors.blue, // Đổi màu của radio button khi được chọn
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
                  if (_selectedStamper == null) {
                    setState(() {
                      managerErrorMessage = 'Vui lòng chọn người đóng dấu hồ sơ';
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
                  final deployedTime = DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now());

                  // Tạo map để lưu các file đã được duyệt
                  final deployedFiles = Map<String, String?>.from(widget.approvedFiles);
                  quantities.forEach((key, value) {
                    deployedFiles[key] = value.toString(); // Cập nhật số lượng đã duyệt
                  });

                  // Cập nhật vào Firebase Realtime Database
                  await FirebaseDatabase.instance.ref().child('files').child(widget.fileId).update({
                    'deployedtime': deployedTime,
                    'deployedFiles': deployedFiles,
                    'status': 'deployed',
                    'stamperName': _selectedStamperName,
                    'comment_manager': _commentController.text, // Thêm nhận xét
                  });
                  // Cập nhật vào Firebase Realtime Database notifications
                  await FirebaseDatabase.instance.ref().child('notifications').child(widget.fileId).update({
                    _selectedStamperName:{
                      'message': 'Có hồ sơ ${widget.name} của ${widget.createdName} cần được đóng dấu vào $deployedTime',
                      'isRead': false,
                    }
                  });
                  await FirebaseDatabase.instance.ref().child('notifications').child(widget.fileId).update({
                    widget.createdName:{
                      'message': 'Hồ sơ ${widget.name} vừa được kiểm tra bởi ${widget.stamperName} vào $deployedTime',
                      'isRead': false,
                    }
                  });
                  // Đợi 2 giây
                  await Future.delayed(const Duration(seconds: 2));

                  // Điều hướng trở về HomeScreen
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text(
                  'Kiểm tra hồ sơ',
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
