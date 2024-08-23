import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            const SizedBox(height: 15),
            // Checkboxes and corresponding TextFields
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
    );
  }

  void _saveData() {
    final Map<String, dynamic> data = {
      'namecreated': widget.fullName,
      'name': _nameController.text,
      'description': _descriptionController.text,
      'original files': _checkboxLabels.asMap().map((index, label) {
        if (_isCheckboxChecked[index] && _textControllers[index].text.isNotEmpty) {
          return MapEntry(label, _textControllers[index].text);
        } else {
          return MapEntry(label, null);
        }
      })..removeWhere((key, value) => value == null),
    };

    if (data['original files']!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn biên bản trình ký và nhập số lượng biên bản')),
      );
      return;
    }

    _databaseReference.push().set(data).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hồ sơ đã được lưu')),
      );
      _nameController.clear();
      _descriptionController.clear();
      // Reset các checkbox và text fields
      setState(() {
        // Cập nhật nội dung của danh sách mà không thay đổi bản thân biến
        for (int i = 0; i < _isCheckboxChecked.length; i++) {
          _isCheckboxChecked[i] = false;
        }
        // Xóa nội dung của tất cả các TextEditingController
        _textControllers.forEach((controller) => controller.clear());
      });
      FocusScope.of(context).requestFocus(FocusNode());
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $error')),
      );
    });
  }
}
