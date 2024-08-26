import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // Package này giúp định dạng ngày giờ
import '../function/detail_screen.dart';
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
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref().child('files');
  String _sortBy = 'title'; // Biến để theo dõi kiểu sắp xếp hiện tại

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    _databaseReference.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        List<Map<dynamic, dynamic>> files = data.values.toList().cast<Map<dynamic, dynamic>>();

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
    } else if (_sortBy == 'timestamp') {
      _files.sort((a, b) {
        DateTime datetimeA = DateFormat('HH:mm dd/MM/yyyy').parse(a['timestamp']);
        DateTime datetimeB = DateFormat('HH:mm dd/MM/yyyy').parse(b['timestamp']);
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
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PopupMenuButton<String>(
              onSelected: _changeSort,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'title',
                  child: Text('Sắp xếp theo tiêu đề'),
                ),
                const PopupMenuItem(
                  value: 'timestamp',
                  child: Text('Sắp xếp theo ngày giờ'),
                ),
              ],
              icon: const Icon(Icons.sort),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(widget.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(_getAuthorDescription(widget.author), style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                _logout(context);
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeScreen(),
          AddNewFileScreen(fullName: widget.fullName),
          const Center(child: Text('Thông báo')),
          const Center(child: Text('Tài khoản')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        iconSize: 35,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Tạo hồ sơ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
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

  Widget _buildHomeScreen() {
    return ListView.builder(
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        return ListTile(
          title: Text(file['title'] ?? 'Tên không xác định'),
          subtitle: Text(file['description'] ?? 'Mô tả không xác định'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(
                  name: file['title'] ?? 'Không có tên',
                  description: file['description'] ?? 'Không có mô tả',
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login');
  }
}
