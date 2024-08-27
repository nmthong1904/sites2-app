import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Thêm thư viện intl để định dạng ngày tháng

class AddNewFileScreen extends StatefulWidget {
  final String fullName;

  const AddNewFileScreen({Key? key, required this.fullName}) : super(key: key);

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
          title: const Text('Thêm hồ sơ mới'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TextFields for "Tên hồ sơ" and "Mô tả"
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên hồ sơ'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _selectAdmin(context),
                child: Text(
                  _selectedAdminName.isEmpty
                      ? 'Chọn người duyệt'
                      : 'Người duyệt: $_selectedAdminName',
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
              const SizedBox(height: 15),
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
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _saveData,
                child: const Text('Lưu hồ sơ'),
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
              title: const Text('Chọn người duyệt'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: adminUsers.length,
                  itemBuilder: (BuildContext context, int index) {
                    final admin = adminUsers[index];
                    final adminId = admin.id;
                    final adminName = admin['fullName'];

                    return ListTile(
                      title: Text(adminName),
                      leading: Radio<String>(
                        value: adminId,
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
                          selectedAdminId = adminId;
                        });
                        setState(() {
                          _selectedAdmin = adminId;
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
        const SnackBar(content: Text('Vui lòng chọn người duyệt hồ sơ')),
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

    String formattedDate = DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now());

    final Map<String, dynamic> data = {
      'namecreated': widget.fullName,
      'title': _nameController.text,
      'description': _descriptionController.text,
      'status': 'pending',
      'timestamp': formattedDate, // Lưu thời gian dưới dạng chuỗi
      'original files': _checkboxLabels.asMap().map((index, label) {
        if (_isCheckboxChecked[index] && _textControllers[index].text.isNotEmpty) {
          return MapEntry(label, _textControllers[index].text);
        } else {
          return MapEntry(label, null);
        }
      })..removeWhere((key, value) => value == null),
      'nameassign': _selectedAdminName,
    };

    _databaseReference.push().set(data).then((_) {
      // Gửi thông báo đến người duyệt hồ sơ
      _sendNotificationToAdmin(
        title: _nameController.text,
        nameCreated: widget.fullName,
        datetime: formattedDate,
        adminName: _selectedAdminName!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hồ sơ đã được lưu')),
      );
      _nameController.clear();
      _descriptionController.clear();
      setState(() {
        for (int i = 0; i < _isCheckboxChecked.length; i++) {
          _isCheckboxChecked[i] = false;
        }
        _textControllers.forEach((controller) => controller.clear());
        _selectedAdmin = null;
        _selectedAdminName = '';
      });
      FocusScope.of(context).requestFocus(FocusNode());
    }).catchError((error) {
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
  }) {
    final DatabaseReference notificationsRef = FirebaseDatabase.instance.ref().child('notifications');

    final Map<String, dynamic> notificationData = {
      'message': 'Có hồ sơ $title mới được tạo bởi $nameCreated vào ngày $datetime',
      'adminId': _selectedAdminName,
      'isRead': false, // Đánh dấu thông báo chưa đọc
    };

    notificationsRef.push().set(notificationData).catchError((error) {
      print('Lỗi gửi thông báo: $error');
    });
  }
}
