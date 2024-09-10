import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home/home_screen.dart';
import 'login/login_screen.dart'; // Import màn hình đăng nhập
import 'login/register_screen.dart'; // Import màn hình đăng ký
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(fullName: 'Tên người dùng', author: 'người dùng'),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}
