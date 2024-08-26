import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Thêm thư viện intl để định dạng ngày tháng
import 'package:fluttertoast/fluttertoast.dart'; // Thư viện để hiển thị Toast


import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Future<void> _register() async {
    String fullName = _fullNameController.text;
    String phone = _phoneController.text;
    String username = _usernameController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    // Kiểm tra tính hợp lệ của các trường thông tin
    if (fullName.isEmpty || phone.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showErrorDialog('Vui lòng điền đầy đủ thông tin.');
      return;
    }

    // Kiểm tra mật khẩu và xác nhận mật khẩu
    if (password != confirmPassword) {
      _showErrorDialog('Mật khẩu và xác nhận mật khẩu không khớp.');
      return;
    }

    // Kiểm tra sự tồn tại của số điện thoại và tên tài khoản
    bool phoneExists = await _checkIfExists('phone', phone);
    bool usernameExists = await _checkIfExists('username', username);

    if (phoneExists) {
      _showErrorDialog('Số điện thoại đã tồn tại.');
      return;
    }

    if (usernameExists) {
      _showErrorDialog('Tên tài khoản đã tồn tại.');
      return;
    }

    // Chuyển đổi thời gian hiện tại thành định dạng DD/MM/YYYY
    String formattedDate = DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now());

    // Lưu thông tin người dùng vào Firestore
    await FirebaseFirestore.instance.collection('users').add({
      'fullName': fullName,
      'phone': phone,
      'username': username,
      'password': password,
      'timestamp': formattedDate, // Lưu thời gian dưới dạng chuỗi
      'author': 'user', // Thêm trường author với giá trị mặc định là 'user'
    });

    Fluttertoast.showToast(
      msg: "Đăng ký thành công",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black,
      textColor: Colors.white,
    );

    // Sau khi đăng ký thành công, điều hướng về trang đăng nhập và xóa tất cả các màn hình trước đó
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // Xóa tất cả các màn hình trước đó
    );
  }

  Future<bool> _checkIfExists(String field, String value) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(field, isEqualTo: value)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Lỗi'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Ký'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
                  (route) => false, // Xóa tất cả các màn hình hiện tại
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Tên người dùng'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
              obscureText: true,
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: const Text('Đăng Ký'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                      (route) => false, // Xóa tất cả các màn hình hiện tại
                );
              },
              child: const Text('Đã có tài khoản? Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}
