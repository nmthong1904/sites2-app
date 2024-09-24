import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart'; // Package này giúp định dạng ngày giờ
import 'package:sites2app/home/notification_screen.dart';
import '../function/detail_screen.dart';
import '../main.dart';
import 'add_newfile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String fullName;
  final String author;

  const HomeScreen({required this.fullName, required this.author, Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Map<dynamic, dynamic>> _files = [];
  int _unreadNotificationsCount = 0;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref().child('files');
  final DatabaseReference _notificationsRef = FirebaseDatabase.instance.ref().child('notifications');
  String _sortBy = 'title'; // Biến để theo dõi kiểu sắp xếp hiện tại

  @override
  void initState() {
    super.initState();
    _loadFiles();
    _loadUnreadNotificationsCount(); // Thêm dòng này
  }

  Future<void> _sendLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
        'your_channel_id',
        'your_channel_name',
        icon: '@mipmap/ic_launcher',  // Specify the icon resource here
        importance: Importance.max,
        priority: Priority.high
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> _loadUnreadNotificationsCount() async {
    _notificationsRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        int count = 0;
        data.forEach((fileId, fileNotifications) {
          if (fileNotifications is Map<dynamic, dynamic>) {
            fileNotifications.forEach((adminName, notificationDetails) {
              // Kiểm tra nếu adminName trùng với widget.fullName và isRead là false
              if (notificationDetails is Map<dynamic, dynamic> &&
                  adminName == widget.fullName &&
                  notificationDetails['isRead'] == false) {
                count++;
              }
            });
          }
        });

        setState(() {
          _unreadNotificationsCount = count;
        });

        // Nếu có thông báo chưa đọc và adminName trùng với widget.fullName thì gửi thông báo
        if (_unreadNotificationsCount > 0 ) {
          if (widget.author == 'user') {
            _sendLocalNotification(
              'Bạn có thông báo mới',
              'Có $_unreadNotificationsCount thông báo chưa đọc.',
            );
          } else if (widget.author == 'admin') {
            _sendLocalNotification(
              'Bạn có thông báo mới',
              'Có $_unreadNotificationsCount hồ sơ trình ký.',
            );
          } else if (widget.author == 'manager') {
            _sendLocalNotification(
              'Bạn có thông báo mới',
              'Có $_unreadNotificationsCount hồ sơ cần được kiểm duyệt.',
            );
          } else if (widget.author == 'stamper') {
            _sendLocalNotification(
              'Bạn có thông báo mới',
              'Có $_unreadNotificationsCount hồ sơ cần được đóng dấu.',
            );
          }
        }
      }
    });
  }

  Future<void> _loadFiles() async {
    _databaseReference.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        List<Map<dynamic, dynamic>> files = data.entries.map((entry) {
          return {
            'id': entry.key, // Lưu trữ fileId
            ...entry.value as Map<dynamic, dynamic>,
          };
        }).toList();

        // Apply filter based on author
        if (widget.author == 'user') {
          files = files.where((file) => file['createdName'] == widget.fullName).toList();
        } else if (widget.author == 'admin') {
          files = files.where((file) => file['approvedName'] == widget.fullName).toList();
        } else if (widget.author == 'manager') {
          files = files.where((file) => file['deployedName'] == widget.fullName).toList();
        } else if (widget.author == 'stamper') {
          files = files.where((file) => file['stamperName'] == widget.fullName).toList();
        }

        setState(() {
          _files = files;
          _sortFiles();
        });
      }
    });
  }

  void _sortFiles() {
    if (_sortBy == 'title') {
      _files.sort((a, b) {
        String titleA = a['title'] ?? '';
        String titleB = b['title'] ?? '';
        return titleA.toLowerCase().compareTo(titleB.toLowerCase());
      });
    } else if (_sortBy == 'createdtime') {
      _files.sort((a, b) {
        DateTime datetimeA = DateFormat('HH:mm dd/MM/yyyy').parse(a['createdtime']);
        DateTime datetimeB = DateFormat('HH:mm dd/MM/yyyy').parse(b['createdtime']);
        return datetimeB.compareTo(datetimeA); // Sắp xếp từ mới nhất đến cũ nhất
      });
    }
  }

  void _changeSort(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      _sortFiles();
    });
  }

  // Hàm để chuyển đổi giá trị author thành tên mô tả
  String _getAuthorDescription(String author) {
    switch (author) {
      case 'admin':
        return 'Ban Giám Đốc';
      case 'manager':
        return 'Nhân Viên Soát Xét Hồ Sơ';
      case 'stamper':
        return 'Nhân Viên Đóng Dấu';
      case 'user':
        return 'Kiểm Định Viên';
      default:
        return 'Chưa Xác Định';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
        title: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: PopupMenuButton<String>(
                onSelected: _changeSort,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'title',
                    child: Text('Tiêu đề: A->Z'),
                  ),
                  const PopupMenuItem(
                    value: 'createdtime',
                    child: Text('Mới nhất'),
                  ),
                ],
                icon: const Icon(Icons.sort),
              ),
            ),
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.fullName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _getAuthorDescription(widget.author),
                    style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  _logout(context);
                },
              ),
            ),
          ],
        ),
      )
          : null, // Không hiển thị AppBar khi không phải trang chủ

      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeScreen(),
          AddNewFileScreen(fullName: widget.fullName, author: widget.author),
          NotificationScreen(fullName: widget.fullName, author: widget.author),
          const Center(child: Text('Tài khoản')),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          if (index == 2) { // Tab thông báo
            await _markAllNotificationsAsRead();
          }
          setState(() {
            _currentIndex = index;
          });
        },
        iconSize: 35,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Tạo hồ sơ',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_unreadNotificationsCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Text(
                        '$_unreadNotificationsCount',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Thông báo',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Tài khoản',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }

  Future<void> _markAllNotificationsAsRead() async {
    final data = (await _notificationsRef.once()).snapshot.value as Map<dynamic, dynamic>?;
    if (data != null) {
      data.forEach((fileId, fileNotifications) {
        if (fileNotifications is Map<dynamic, dynamic>) {
          fileNotifications.forEach((adminName, notificationDetails) {
            if (notificationDetails is Map<dynamic, dynamic> && adminName == widget.fullName) {
              _notificationsRef.child(fileId).child(adminName).update({'isRead': true});
            }
          });
        }
      });
      _loadUnreadNotificationsCount(); // Làm mới số lượng thông báo chưa đọc
    }
  }

  Widget _buildHomeScreen() {
    return ListView.builder(
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        final originalFiles = (file['original files'] as Map<dynamic, dynamic>?)?.cast<String, String?>() ?? {};
        final approvedFiles = (file['approvedFiles'] as Map<dynamic, dynamic>?)?.cast<String, String?>() ?? {};
        final deployedFiles = (file['deployedFiles'] as Map<dynamic, dynamic>?)?.cast<String, String?>() ?? {};

        return ListTile(
          title: RichText(
            text: TextSpan(
              children: <TextSpan>[
                const TextSpan(
                  text: 'Tiêu đề: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.black,height: 1.5),
                ),
                TextSpan(
                  text: file['title'],
                  style: const TextStyle(fontSize: 16,color: Colors.black,height: 1.5),
                ),
              ],
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: <TextSpan>[
                    const TextSpan(
                      text: 'Trạng thái: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.black,height: 1.5),
                    ),
                    TextSpan(
                      text: _getStatusText(file['status']),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(file['status']), // Thay đổi màu sắc dựa trên status
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  children: <TextSpan>[
                    const TextSpan(
                      text: 'Ngày tạo: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.black,height: 1.5),
                    ),
                    TextSpan(
                      text: file['createdtime'],
                      style: const TextStyle(fontSize: 16,color: Colors.black,height: 1.5),
                    ),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  children: <TextSpan>[
                    const TextSpan(
                      text: 'Người trình ký: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.black,height: 1.5),
                    ),
                    TextSpan(
                      text: file['createdName'],
                      style: const TextStyle(fontSize: 16,color: Colors.black,height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.circle,
            color: _getStatusColor(file['status']),
            size: 14.0, // Adjust the size of the dot
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(
                  name: file['title'] ?? 'Không có tên',
                  description: file['description'] ?? 'Không có mô tả',
                  status: file['status'] ?? 'Chưa xác định',
                  datetime: file['createdtime'] ?? 'Chưa xác định',
                  originalFiles: originalFiles,
                  nameCreated: file['createdName'] ?? 'Không có thông tin',
                  author: widget.author,
                  fileId: file['id'], // Truyền fileId vào đây
                  approvedFiles: approvedFiles, // Truyền approvedFiles
                  approvedtime: file['approvedtime'], // Truyền approvedtime
                  approvedName: file['approvedName'], // Truyền approvedName
                  deployedFiles: deployedFiles, // Truyền deployedFiles
                  deployedtime: file['deployedtime'], // Truyền deployedtime
                  deployedName: file['deployedName'], // Truyền deployedName
                  stampertime: file['stampertime'], // Truyền deployedtime
                  stamperName: file['stamperName'], // Truyền stamperName
                ),
              ),
            );
          },
        );
      },
    );
  }
  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
      case 'deployed':
      case 'pending':
        return Colors.lightBlueAccent;
      case 'finished':
        return Colors.green;
      case 'denied':
        return Colors.red;
      default:
        return Colors.grey; // Default color if the status is not recognized
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Đang chờ phê duyệt';
      case 'approved':
        return 'Đang chờ kiểm tra';
      case 'deployed':
        return 'Đang chờ đóng dấu';
      case 'finished':
        return 'Hồ sơ đã hoàn thiện';
      default:
        return 'Trạng thái không xác định';
    }
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login');
  }
}
