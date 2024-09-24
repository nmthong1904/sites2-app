import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'home_screen.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationScreen extends StatefulWidget {
  final String fullName;
  final String author;

  const NotificationScreen({Key? key, required this.fullName, required this.author}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final DatabaseReference _notificationsRef = FirebaseDatabase.instance.ref().child('notifications');
  List<Map<dynamic, dynamic>> _notifications = [];
  List<String> _notificationKeys = []; // Add a list to store the keys

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    _notificationsRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        List<Map<dynamic, dynamic>> notifications = [];
        List<String> keys = [];

        data.forEach((fileId, fileNotifications) {
          if (fileNotifications is Map<dynamic, dynamic>) {
            fileNotifications.forEach((adminName, notificationDetails) {
              if (notificationDetails is Map<dynamic, dynamic>) {
                // So sánh trực tiếp với widget.fullName
                if (adminName == widget.fullName) {
                  notifications.add(notificationDetails);
                  keys.add(fileId); // Lưu lại fileId làm key
                }
              }
            });
          }
        });

        setState(() {
          _notifications = notifications;
          _notificationKeys = keys;
        });
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        centerTitle: true, // Đảm bảo tiêu đề nằm giữa AppBar
      ),
      body: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          final notificationKey = _notificationKeys[index]; // Get the key for this notification
          return ListTile(
            subtitle: Text(notification['message'] ?? 'Nội dung không có'),
            onTap: () {
              // Cập nhật trạng thái thông báo khi người dùng xem
              if (notification['isRead'] == false) {
                _notificationsRef.child(notificationKey).child(widget.fullName).update({'isRead': true});
              }
            },
          );
        },
      ),
    );
  }
}
