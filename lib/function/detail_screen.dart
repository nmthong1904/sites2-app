import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sites2app/function/processingdialog_screen.dart';
import 'approved_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_database/firebase_database.dart';
import 'deployed_screen.dart';
import 'package:intl/intl.dart'; // Thêm thư viện intl để định dạng ngày tháng

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
  final String? approvedName; // Thêm approvedtime
  final Map<String, String?> deployedFiles; // Thêm approvedFiles
  final String? deployedtime; // Thêm approvedtime
  final String? deployedName; // Thêm approvedName
  final String? stampertime; // Thêm approvedtime
  final String? stamperName; // Thêm approvedName

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
    required this.approvedName, // Thêm approvedName
    required this.deployedFiles, // Thêm approvedFiles
    required this.deployedtime, // Thêm deployedtime
    required this.deployedName, // Thêm deployedName
    required this.stampertime, // Thêm stampertime
    required this.stamperName, // Thêm deployedName
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

  String getApprovedStatus(Map<String, String?> originalFiles, Map<String, String?> approvedFiles) {
    bool isComplete = true;
    String incompleteDetails = '';

    originalFiles.forEach((key, originalValue) {
      int originalIntValue = int.tryParse(originalValue ?? '0') ?? 0;
      int approvedIntValue = int.tryParse(approvedFiles[key] ?? '0') ?? 0;

      incompleteDetails += '$key: $approvedIntValue/$originalIntValue\n'; // Thêm tất cả các phần tử

      if (approvedIntValue < originalIntValue) {
        isComplete = false;
      }
    });

    if (isComplete) {
      return 'Hồ sơ trình ký hoàn chỉnh';
    } else {
      return 'Hồ sơ trình ký được phê duyệt\n$incompleteDetails';
    }
  }
  String getDeployedStatus(Map<String, String?> approvedFiles, Map<String, String?> deployedFiles) {
    bool isComplete = true;
    String incompleteDetails = '';

    approvedFiles.forEach((key, approvedValue) {
      int approvedIntValue = int.tryParse(approvedValue ?? '0') ?? 0;
      int deployedIntValue = int.tryParse(deployedFiles[key] ?? '0') ?? 0;

      incompleteDetails += '$key: $deployedIntValue/$approvedIntValue\n'; // Thêm tất cả các phần tử

      if (deployedIntValue < approvedIntValue) {
        isComplete = false;
      }
    });

    if (isComplete) {
      return 'Hồ sơ kiểm tra hoàn chỉnh';
    } else {
      return 'Hồ sơ kiểm tra đạt yêu cầu\n$incompleteDetails';
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
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mô tả: ${widget.description}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Trạng thái: ${_getStatusText(widget.status)}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Ngày tạo hồ sơ: ${widget.datetime}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Người tạo: ${widget.nameCreated}',
                  style: const TextStyle(fontSize: 16),
                ),
                if (widget.approvedName != null && widget.status != 'pending') ...[
                  const SizedBox(height: 8), // Khoảng cách
                  Text('Người ký hồ sơ: ${widget.approvedName}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
                if (widget.approvedtime != null) ...[
                  Text('Thời gian ký hồ sơ: ${widget.approvedtime}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
                if (widget.deployedName != null && widget.status != 'approved') ...[
                  const SizedBox(height: 8), // Khoảng cách
                  Text('Người kiểm tra hồ sơ: ${widget.deployedName}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
                if (widget.deployedtime != null) ...[
                  Text('Thời gian kiểm tra: ${widget.deployedtime}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
                if (widget.stamperName != null  && widget.status != 'deployed' ) ...[
                  const SizedBox(height: 8), // Khoảng cách
                  Text('Người đóng dấu hồ sơ: ${widget.stamperName}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
                if (widget.stampertime != null) ...[
                  Text('Thời gian đóng dấu: ${widget.stampertime}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8), // Khoảng cách
            if (widget.status == 'pending') ...[
              Text('Biên bản gốc bao gồm', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ...widget.originalFiles.entries.map((entry) {
                return Text('${entry.value ?? 'Không có dữ liệu'} ${entry.key}', style: const TextStyle(fontSize: 16));
              }).toList(),
            ] else if (widget.status == 'approved')...[
              // Hiển thị trạng thái so sánh
              Text(getApprovedStatus(widget.originalFiles, widget.approvedFiles), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ] else ...[
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: getApprovedStatus(widget.originalFiles, widget.approvedFiles),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.black),
                    ),
                    const WidgetSpan(
                      child: SizedBox(height: 24), // Sử dụng WidgetSpan để thêm khoảng cách
                    ),
                    TextSpan(
                      text: getDeployedStatus(widget.approvedFiles, widget.deployedFiles),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              )
            ],
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
                    _navigateToDeployScreen(context);
                  },
                  child: const Text('Kiểm tra hồ sơ'),
                ),
              ),
            ] else if (widget.author == 'stamper') ...[
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    // Hiển thị màn hình xử lý
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return const ProcessingdialogScreen();
                      },
                    );
                    final stamperTime = DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now());
                    // Xử lý logic đóng dấu
                    await FirebaseDatabase.instance.ref().child('files').child(widget.fileId).update({
                      'stampertime': stamperTime,
                      'status':'finished'
                    });
                    // Cập nhật vào Firebase Realtime Database notifications
                    await FirebaseDatabase.instance.ref().child('notifications').child(widget.fileId).update({
                      widget.nameCreated:{
                        'message': 'Hồ sơ ${widget.name} của ${widget.nameCreated} đã được dóng dấu vào $stamperTime',
                        'isRead': false,
                      }
                    });
                    // Đợi 2 giây
                    await Future.delayed(const Duration(seconds: 2));

                    // Điều hướng trở về HomeScreen
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Đóng Dấu Hồ Sơ'),
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
          child: ApproveScreen(originalFiles: widget.originalFiles,
            fileId: widget.fileId,
            name: widget.name,
            createdName: widget.nameCreated,
            approvedName: widget.approvedName!,
          ),
        );
      },
    );
  }
  void _navigateToDeployScreen(BuildContext context) {
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
          child: DeployedScreen(approvedFiles: widget.approvedFiles,
              fileId: widget.fileId,
              name: widget.name,
              createdName: widget.nameCreated,
              stamperName: widget.deployedName!,
          ),
        );
      },
    );
  }
}
