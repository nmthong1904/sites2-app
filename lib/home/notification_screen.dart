import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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

        data.forEach((key, value) {
          notifications.add(value);
          keys.add(key); // Store each key associated with the notification
        });

        // Apply filter based on author
        if (widget.author == 'user') {
          notifications = notifications.where((file) => file['userId'] == widget.fullName).toList();
        } else if (widget.author == 'admin') {
          notifications = notifications.where((file) => file['adminId'] == widget.fullName).toList();
        } else if (widget.author == 'manager') {
          notifications = notifications.where((file) => file['managerId'] == widget.fullName).toList();
        } else if (widget.author == 'stamper') {
          notifications = notifications.where((file) => file['stamperId'] == widget.fullName).toList();
        }

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
        title: const Text('Thông Báo'),
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
                _notificationsRef.child(notificationKey).update({'isRead': true});
              }
            },
          );
        },
      ),
    );
  }
}
