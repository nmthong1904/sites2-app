import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
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
  late Stream<DatabaseEvent> _filesStream; // Đổi kiểu của _filesStream
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref().child('files');

  @override
  void initState() {
    super.initState();
    _filesStream = _databaseReference.onValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0), // Tạo khoảng cách 10dp từ trên xuống
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(widget.author, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                _logout(context);
              },
            ),
          ),
        ],
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
    return StreamBuilder<DatabaseEvent>( // Đổi kiểu của StreamBuilder
      stream: _filesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data == null || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('Không có dữ liệu'));
        }

        final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        final List<Map<dynamic, dynamic>> files = data.values.toList().cast<Map<dynamic, dynamic>>();

        return ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            return ListTile(
              title: Text(file['name'] ?? 'Không có tên'),
              subtitle: Text(file['description'] ?? 'Không có mô tả'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      name: file['name'] ?? 'Không có tên',
                      description: file['description'] ?? 'Không có mô tả',
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}
