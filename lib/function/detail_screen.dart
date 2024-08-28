import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'approved_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ProductDetailScreen extends StatefulWidget {
  final String name;
  final String description;
  final String status;
  final String datetime;
  final Map<String, String?> originalFiles;
  final String nameCreated;
  final String author;
  final String fileId;
  final Map<String, String?> approvedFiles; // Thêm approvedFiles
  final String? approvedtime; // Thêm approvedtime
  final String? assignName; // Thêm approvedtime
  final String? approvedName; // Thêm approvedName

  const ProductDetailScreen({
    required this.name,
    required this.description,
    required this.status,
    required this.datetime,
    required this.originalFiles,
    required this.nameCreated,
    required this.author,
    required this.fileId,
    required this.approvedFiles, // Thêm approvedFiles
    required this.approvedtime, // Thêm approvedtime
    required this.assignName, // Thêm approvedName
    required this.approvedName, // Thêm approvedName
    Key? key,
  }) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Đang chờ phê duyệt';
      case 'approved':
        return 'Đang chờ soát xét';
      case 'deployed':
        return 'Đang chờ đóng dấu';
      case 'finished':
        return 'Hồ sơ đã hoàn thiện';
      default:
        return 'Trạng thái không xác định';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết hồ sơ'),
        actions: widget.author == 'user'
            ? [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // Xử lý xóa hồ sơ
              },
            ),
          ),
        ]
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tiêu đề: ${widget.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Mô tả: ${widget.description}\n',
                    style: const TextStyle(fontSize: 16),
                  ),
                  TextSpan(
                    text: 'Trạng thái: ${_getStatusText(widget.status)}\n',
                    style: const TextStyle(fontSize: 16),
                  ),
                  TextSpan(
                    text: 'Ngày tạo hồ sơ: ${widget.datetime}\n',
                    style: const TextStyle(fontSize: 16),
                  ),
                  TextSpan(
                    text: 'Người tạo: ${widget.nameCreated}\n',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              style: const TextStyle(height: 1.5),
            ),
            Text.rich(
                TextSpan(
                children:[
                  if (widget.approvedtime != null)
                    TextSpan(
                      text: 'Thời gian phê duyệt: ${widget.approvedtime}\n',
                      style: const TextStyle(fontSize: 16),
                    ),
                  if (widget.approvedName != null)
                    TextSpan(
                      text: 'Người phê duyệt: ${widget.assignName}\n',
                      style: const TextStyle(fontSize: 16),
                    ),
                ],
              ),
            ),
            Text('Biên bản gốc bao gồm', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...widget.originalFiles.entries.map((entry) {
              return Text('${entry.value ?? 'Không có dữ liệu'} ${entry.key}', style: const TextStyle(fontSize: 16));
            }).toList(),
            const SizedBox(height: 10),
            // Hiển thị các dữ liệu mới nếu có
            if (widget.approvedFiles.isNotEmpty) ...[
              Text('Biên bản đã phê duyệt:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ...widget.approvedFiles.entries.map((entry) {
                return Text('${entry.value ?? 'Không có dữ liệu'} ${entry.key}', style: const TextStyle(fontSize: 16));
              }).toList(),
            ],
            const SizedBox(height: 10),
            // Hiển thị các nút hành động tùy theo vai trò của author
            if (widget.author == 'admin') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _navigateToApproveScreen(context);
                    },
                    child: const Text('Phê duyệt hồ sơ'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Xử lý từ chối hồ sơ
                    },
                    child: const Text('Từ chối hồ sơ'),
                  ),
                ],
              ),
            ] else if (widget.author == 'manager') ...[
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Xử lý logic hoàn thành soát xét
                  },
                  child: const Text('Đã Soát Xét Hồ Sơ'),
                ),
              ),
            ] else if (widget.author == 'stamper') ...[
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Xử lý logic đóng dấu
                  },
                  child: const Text('Đã Đóng Dấu Hồ Sơ'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  void _navigateToApproveScreen(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Cho phép điều chỉnh chiều cao của modal
      backgroundColor: Colors.transparent, // Nền trong suốt
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.only(top: 8.0), // Khoảng cách trên để xem phần màn hình dưới
          height: MediaQuery.of(context).size.height * 0.75, // Chiếm 3/4 chiều cao màn hình
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
          child: ApproveScreen(originalFiles: widget.originalFiles,fileId: widget.fileId),
        );
      },
    );
  }
}
