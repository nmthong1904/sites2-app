import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


import '/home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true; // Biến trạng thái để kiểm soát hiển thị mật khẩu

  Future<void> _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(
        msg: "Vui lòng nhập tên người dùng và mật khẩu.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
      return;
    }

    try {
      // Truy vấn Firestore để kiểm tra username và password
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .get();

      if (result.docs.isNotEmpty) {
        // Lấy họ tên và author từ Firestore
        var userData = result.docs.first.data() as Map<String, dynamic>;
        String fullName = userData['fullName'] ?? 'N/A';
        String author = userData['author'] ?? 'user'; // Sử dụng giá trị gốc 'author'
        String userId = result.docs.first.id; // Lấy userId (Document ID)

        // Lưu FCM Token
        await _saveFCMToken(userId);

        // Đăng nhập thành công
        Fluttertoast.showToast(
          msg: "Đăng nhập thành công!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.black,
          textColor: Colors.white,
        );

        // Điều hướng đến HomeScreen với dữ liệu họ tên và author
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(fullName: fullName, author: author),
          ),
        );
      } else {
        // Đăng nhập thất bại
        Fluttertoast.showToast(
          msg: "Tên người dùng hoặc mật khẩu không đúng.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      // Xử lý lỗi
      Fluttertoast.showToast(
        msg: "Đã xảy ra lỗi trong quá trình đăng nhập.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      print(e.toString());
    }
  }
  // Hàm lưu FCM Token vào Firestore
  Future<void> _saveFCMToken(String userId) async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      // Lưu token dưới đường dẫn users/userId/token
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'token': token,
      }).catchError((error) async {
        // Nếu không tồn tại document, tạo mới
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'token': token,
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Nhập'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Tên người dùng'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword; // Đổi trạng thái khi nhấn vào icon
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword, // Hiển thị hoặc ẩn mật khẩu dựa trên trạng thái
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Đăng Nhập'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/register');
              },
              child: const Text('Chưa có tài khoản? Đăng ký'),
            ),
          ],
        ),
      ),
    );
  }
}
