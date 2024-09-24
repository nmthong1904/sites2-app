import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../function/processingdialog_screen.dart';
import 'home_screen.dart'; // Thêm thư viện intl để định dạng ngày tháng

class AddNewFileScreen extends StatefulWidget {
  final String fullName;
  final String author;

  const AddNewFileScreen({Key? key, required this.fullName, required this.author}) : super(key: key);

  @override
  _AddNewFileScreenState createState() => _AddNewFileScreenState();
}

class _AddNewFileScreenState extends State<AddNewFileScreen> {
  final List<String> _checkboxLabels = [
    'Biên bản Nồi Hơi',
    'Biên bản TBAL',
    'Biên bản Hệ Thống Lạnh',
    'Biên bản TBĐ',
    'Biên bản Áp Kế',
    'Biên bản Van An Toàn',
    'Biên bản NDT',
    'Biên bản Huấn Luyện',
    'Biên bản Môi Trường',
    'Biên bản khác',
  ];

  final List<bool> _isCheckboxChecked = List.generate(10, (index) => false);
  final List<TextEditingController> _textControllers = List.generate(10, (index) => TextEditingController());

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref().child('files');

  String? _selectedAdmin;
  String _selectedAdminName = '';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Ẩn bàn phím khi người dùng nhấp ra ngoài các trường nhập liệu
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tạo hồ sơ trình ký'),
          centerTitle: true, // Đảm bảo tiêu đề nằm giữa AppBar
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TextFields for "Tên hồ sơ" and "Mô tả"
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tiêu đề',
                  labelStyle: const TextStyle(color: Colors.blue),
                  filled: true,
                  fillColor: Colors.blue[50],
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.blue[800]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.blue[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  labelStyle: const TextStyle(color: Colors.blue),
                  filled: true,
                  fillColor: Colors.blue[50],
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.blue[800]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.blue[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              TextButton(
                onPressed: () => _selectAdmin(context),
                child: Text(
                  _selectedAdminName.isEmpty
                      ? 'Chọn người trình ký hồ sơ'
                      : 'Người trình ký: $_selectedAdminName',
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
              ...List.generate(10, (index) {
                return Row(
                  children: [
                    Checkbox(
                      value: _isCheckboxChecked[index],
                      onChanged: (bool? value) {
                        setState(() {
                          _isCheckboxChecked[index] = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(_checkboxLabels[index]),
                    ),
                    if (_isCheckboxChecked[index])
                      Expanded(
                        child: TextField(
                          controller: _textControllers[index],
                          decoration: const InputDecoration(
                            labelText: 'Số lượng biên bản',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                  ],
                );
              }),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: _saveData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.blue[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(350, 50), // Cố định độ dài của nút
                  ),
                  child: const Text(
                    'Tạo hồ sơ',
                    style: TextStyle(color: Colors.white), // Màu chữ trắng
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectAdmin(BuildContext context) async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('author', isEqualTo: 'admin')
        .get();

    final List<QueryDocumentSnapshot> adminUsers = querySnapshot.docs;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedAdminId = _selectedAdmin;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: const Text('Chọn người trình ký'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: adminUsers.length,
                  itemBuilder: (BuildContext context, int index) {
                    final admin = adminUsers[index];
                    final adminName = admin['fullName'];

                    return ListTile(
                      title: Text(adminName),
                      leading: Radio<String>(
                        value: adminName,
                        groupValue: selectedAdminId,
                        onChanged: (String? value) {
                          // Cập nhật trạng thái và đóng dialog khi nhấn vào RadioButton
                          setStateDialog(() {
                            selectedAdminId = value;
                          });
                          setState(() {
                            _selectedAdmin = selectedAdminId;
                            _selectedAdminName = adminName;
                          });
                          Navigator.of(context).pop();
                        },
                        activeColor: Colors.blue, // Đổi màu của radio button khi được chọn
                      ),
                      onTap: () {
                        // Cập nhật trạng thái và đóng dialog khi nhấn vào ListTile
                        setStateDialog(() {
                          selectedAdminId = adminName;
                        });
                        setState(() {
                          _selectedAdmin = adminName;
                          _selectedAdminName = adminName;
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Hủy'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveData() {
    // Kiểm tra đầu vào trước khi lưu
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề')),
      );
      return;
    }

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mô tả')),
      );
      return;
    }

    if (_selectedAdmin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn người trình ký hồ sơ')),
      );
      return;
    }

    bool isAnyCheckboxChecked = false;
    for (int i = 0; i < _isCheckboxChecked.length; i++) {
      if (_isCheckboxChecked[i] && _textControllers[i].text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng nhập số lượng cho "${_checkboxLabels[i]}"')),
        );
        return;
      }
      if (_isCheckboxChecked[i]) {
        isAnyCheckboxChecked = true;
      }
    }

    if (!isAnyCheckboxChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn loại biên bản')),
      );
      return;
    }

    // Hiển thị dialog xử lý trước khi lưu dữ liệu
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ProcessingdialogScreen();
      },
    );

    String formattedDate = DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now());

    final Map<String, dynamic> data = {
      'createdName': widget.fullName,
      'title': _nameController.text,
      'description': _descriptionController.text,
      'status': 'pending',
      'createdtime': formattedDate,
      'original files': _checkboxLabels.asMap().map((index, label) {
        if (_isCheckboxChecked[index] && _textControllers[index].text.isNotEmpty) {
          return MapEntry(label, _textControllers[index].text);
        } else {
          return MapEntry(label, null);
        }
      })..removeWhere((key, value) => value == null),
      'approvedName': _selectedAdminName,
    };

    // Tạo một DatabaseReference mới cho hồ sơ
    DatabaseReference newFileRef = _databaseReference.push();

    // Lưu hồ sơ và nhận ID của nó
    newFileRef.set(data).then((_) {
      String fileId = newFileRef.key!; // Lấy ID của phần tử đã lưu

      // Gửi thông báo với ID của hồ sơ
      _sendNotificationToAdmin(
        title: _nameController.text,
        nameCreated: widget.fullName,
        datetime: formattedDate,
        adminName: _selectedAdminName!,
        fileId: fileId, // Thêm ID của hồ sơ vào thông báo
      );

      // Đợi một khoảng thời gian để giả lập xử lý
      Future.delayed(Duration(seconds: 2), () {
        Navigator.of(context).pop(); // Đóng dialog xử lý
        // Quay lại màn hình HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(fullName: widget.fullName, author: widget.author),
          ),
        );
      });
    }).catchError((error) {
      Navigator.of(context).pop(); // Đóng dialog nếu gặp lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $error')),
      );
    });
  }

  void _sendNotificationToAdmin({
    required String title,
    required String nameCreated,
    required String datetime,
    required String adminName,
    required String fileId, // Thêm fileId vào tham số
  }) {
    final DatabaseReference notificationsRef = FirebaseDatabase.instance.ref().child('notifications').child(fileId);

    final Map<String, dynamic> notificationData = {
      adminName:{
        'message': 'Có hồ sơ $title mới được trình ký bởi $nameCreated vào $datetime',
        'isRead': false,
      }
    };

    notificationsRef.set(notificationData).catchError((error) {
      print('Lỗi gửi thông báo: $error');
    });
  }
}
