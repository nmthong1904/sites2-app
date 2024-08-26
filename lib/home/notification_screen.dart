import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final DatabaseReference _notificationsRef = FirebaseDatabase.instance.ref().child('notifications');
  List<Map<dynamic, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    _notificationsRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        List<Map<dynamic, dynamic>> notifications = data.values.toList().cast<Map<dynamic, dynamic>>();

        setState(() {
          _notifications = notifications;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông Báo'),
      ),
      body: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return ListTile(
            subtitle: Text(notification['message'] ?? 'Nội dung không có'),
            onTap: () {
              // Cập nhật trạng thái thông báo khi người dùng xem
              if (notification['isRead'] == false) {
                _notificationsRef.child(notification['adminId']).update({'isRead': true});
              }
            },
          );
        },
      ),
    );
  }
}
