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
  final String? description;
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
  final String? commentAdmin; // Thêm approvedName
  final String? commentManager; // Thêm approvedName

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
    required this.commentAdmin, // Thêm deployedName
    required this.commentManager, // Thêm deployedName
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
      case 'denied':
        return 'Hồ sơ đã bị từ chối';
      default:
        return 'Trạng thái không xác định';
    }
  }

  RichText getApprovedStatus(Map<String, String?> originalFiles, Map<String, String?> approvedFiles) {
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
      return RichText(
        text: const TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: 'Hồ sơ trình ký hoàn chỉnh\n',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
                height: 1.5
              ),
            ),
          ],
        ),
      );
    } else {
      return RichText(
        text: TextSpan(
          children: <TextSpan>[
            const TextSpan(
              text: 'Hồ sơ trình ký được phê duyệt\n',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.5
              ),
            ),
            TextSpan(
              text: incompleteDetails,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
                height: 1.5
              ),
            ),
          ],
        ),
      );
    }
  }

  RichText getDeployedStatus(Map<String, String?> approvedFiles, Map<String, String?> deployedFiles) {
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
      return RichText(
        text: const TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: 'Hồ sơ kiểm tra hoàn chỉnh\n',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
                height: 1.5
              ),
            ),
          ],
        ),
      );
    } else {
      return RichText(
        text: TextSpan(
          children: <TextSpan>[
            const TextSpan(
              text: 'Hồ sơ kiểm tra đạt yêu cầu\n',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.5
              ),
            ),
            TextSpan(
              text: incompleteDetails,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
                height: 1.5
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết hồ sơ'),
        centerTitle: true, // Đảm bảo tiêu đề nằm giữa AppBar
        actions: widget.author == 'user'
            ? [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDeleteFile, // Gọi hàm hiển thị hộp thoại xác nhận
            ),
          ),
        ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: <TextSpan>[
                  const TextSpan(
                    text: 'Tiêu đề: ',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: Colors.black),
                  ),
                  TextSpan(
                    text: widget.name,
                    style: const TextStyle(fontSize: 20,color: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.description != "") ...[
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        const TextSpan(
                          text: 'Mô tả/Ghi chú: ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.black,height: 1.5),
                        ),
                        TextSpan(
                          text: widget.description,
                          style: const TextStyle(fontSize: 16,color: Colors.black,height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
                RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      const TextSpan(
                        text: 'Trạng thái: ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.black,height: 1.5),
                      ),
                      TextSpan(
                        text: _getStatusText(widget.status),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(widget.status), // Thay đổi màu sắc dựa trên status
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
                        text: 'Ngày tạo hồ sơ: ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.black,height: 1.5),
                      ),
                      TextSpan(
                        text: widget.datetime,
                        style: const TextStyle(fontSize: 16,color: Colors.black,height: 1.5),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      const TextSpan(
                        text: 'Người tạo: ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.black,height: 1.5),
                      ),
                      TextSpan(
                        text: widget.nameCreated,
                        style: const TextStyle(fontSize: 16,color: Colors.black,height: 1.5),
                      ),
                    ],
                  ),
                ),
                if (widget.approvedName != null && widget.status != 'pending') ...[
                  const SizedBox(height: 8), // Khoảng cách
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        const TextSpan(
                          text: 'Người ký hồ sơ: ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.black,height: 1.5),
                        ),
                        TextSpan(
                          text: widget.approvedName,
                          style: const TextStyle(fontSize: 16,color: Colors.black,height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.approvedtime != null) ...[
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        const TextSpan(
                          text: 'Thời gian ký hồ sơ: ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.black,height: 1.5),
                        ),
                        TextSpan(
                          text: widget.approvedtime,
                          style: const TextStyle(fontSize: 16,color: Colors.black,height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.deployedName != null && widget.status != 'approved') ...[
                  const SizedBox(height: 8), // Khoảng cách
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        const TextSpan(
                          text: 'Người kiểm tra hồ sơ: ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.black,height: 1.5),
                        ),
                        TextSpan(
                          text: widget.deployedName,
                          style: const TextStyle(fontSize: 16,color: Colors.black,height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.deployedtime != null) ...[
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        const TextSpan(
                          text: 'Thời gian kiểm tra: ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.black,height: 1.5),
                        ),
                        TextSpan(
                          text: widget.deployedtime,
                          style: const TextStyle(fontSize: 16,color: Colors.black,height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.stamperName != null  && widget.status != 'deployed' ) ...[
                  const SizedBox(height: 8), // Khoảng cách
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        const TextSpan(
                          text: 'Người đóng dấu hồ sơ: ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.black,height: 1.5),
                        ),
                        TextSpan(
                          text: widget.stamperName,
                          style: const TextStyle(fontSize: 16,color: Colors.black,height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.stampertime != null) ...[
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        const TextSpan(
                          text: 'Thời gian đóng dấu: ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.black,height: 1.5),
                        ),
                        TextSpan(
                          text: widget.stampertime,
                          style: const TextStyle(fontSize: 16,color: Colors.black,height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8), // Khoảng cách
            if (widget.commentAdmin != null) ...[
              RichText(
                text: TextSpan(
                  children: <TextSpan>[
                    const TextSpan(
                      text: 'Nhận xét của Ban Giám Đốc: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.black,height: 1.5),
                    ),
                    TextSpan(
                      text: widget.commentAdmin,
                      style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: Colors.yellow[800],height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.commentManager != null) ...[
              RichText(
                text: TextSpan(
                  children: <TextSpan>[
                    const TextSpan(
                      text: 'Nhận xét của Bộ Phận Kiểm Tra Hồ Sơ: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.black,height: 1.5),
                    ),
                    TextSpan(
                      text: widget.commentManager,
                      style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: Colors.yellow[800],height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8), // Khoảng cách
            if (widget.status == 'pending') ...[
              Text('Biên bản gốc bao gồm', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ...widget.originalFiles.entries.map((entry) {
                return Text('${entry.value ?? 'Không có dữ liệu'} ${entry.key}', style: const TextStyle(fontSize: 16));
              }).toList(),
            ] else if (widget.status == 'approved')...[
              // Hiển thị trạng thái so sánh
              getApprovedStatus(widget.originalFiles, widget.approvedFiles),
            ] else if (widget.status == 'deployed' || widget.status == 'finished') ...[
              RichText(
                text: TextSpan(
                  children: [
                    getApprovedStatus(widget.originalFiles, widget.approvedFiles).text, // TextSpan từ RichText
                    const WidgetSpan(
                      child: SizedBox(height: 28), // Thêm khoảng cách giữa các phần
                    ),
                    getDeployedStatus(widget.originalFiles, widget.deployedFiles).text, // TextSpan từ RichText
                  ],
                ),
              ),
            ] else if (widget.status == 'denied') ...[
              //Không hiển thị gì khi hồ sơ bị từ chối
            ],
            const SizedBox(height: 10),
            Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Căn giữa theo chiều dọc
                  crossAxisAlignment: CrossAxisAlignment.center, // Căn giữa theo chiều ngang
                  children: [
                    // Hiển thị các nút hành động tùy theo vai trò của author
                    if (widget.author == 'admin' && widget.status == 'pending') ...[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center, // Căn giữa các nút hành động
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _navigateToApproveScreen(context);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: Colors.blue[800],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              minimumSize: const Size(300, 50),
                            ),
                            child: const Text(
                              'Phê duyệt hồ sơ',
                              style: TextStyle(color: Colors.white), // Màu chữ trắng
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () async {
                              _showDenialReasonDialog(context); // Gọi hàm hiển thị dialog nhập lý do từ chối
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: Colors.blue[800],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              minimumSize: const Size(300, 50),
                            ),
                            child: const Text(
                              'Từ chối hồ sơ',
                              style: TextStyle(color: Colors.white), // Màu chữ trắng
                            ),
                          ),
                        ],
                      ),
                    ] else if (widget.author == 'manager'  && widget.status == 'approved') ...[
                      ElevatedButton(
                        onPressed: () {
                          _navigateToDeployScreen(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.blue[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          minimumSize: const Size(300, 50),
                        ),
                        child: const Text(
                          'Kiểm tra hồ sơ',
                          style: TextStyle(color: Colors.white), // Màu chữ trắng
                        ),
                      ),
                    ] else if (widget.author == 'stamper'  && widget.status == 'deployed') ...[
                      ElevatedButton(
                        onPressed: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return const ProcessingdialogScreen();
                            },
                          );
                          final stamperTime = DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now());
                          await FirebaseDatabase.instance.ref().child('files').child(widget.fileId).update({
                            'stampertime': stamperTime,
                            'status': 'finished'
                          });
                          await FirebaseDatabase.instance.ref().child('notifications').child(widget.fileId).update({
                            widget.nameCreated: {
                              'message': 'Hồ sơ ${widget.name} của ${widget.nameCreated} đã được đóng dấu vào $stamperTime',
                              'isRead': false,
                            }
                          });
                          await Future.delayed(const Duration(seconds: 2));
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.blue[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          minimumSize: const Size(300, 50),
                        ),
                        child: const Text(
                          'Đóng Dấu Hồ Sơ',
                          style: TextStyle(color: Colors.white), // Màu chữ trắng
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDenialReasonDialog(BuildContext context) {
    String commentDenied = ''; // Biến để lưu lý do từ chối

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.75, // Chiếm 3/4 chiều ngang
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Nhập lý do từ chối',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: (value) {
                    commentDenied = value; // Cập nhật lý do khi người dùng nhập
                  },
                  decoration: const InputDecoration(
                    hintText: 'Nhập lý do...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3, // Có thể nhập nhiều dòng
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      child: const Text('Hủy'),
                      onPressed: () {
                        Navigator.of(context).pop(); // Đóng dialog
                      },
                    ),
                    TextButton(
                      child: const Text('Xác nhận'),
                      onPressed: () {
                        // Nếu lý do từ chối không rỗng, tiến hành xử lý
                        if (commentDenied.isNotEmpty) {
                          // Hiển thị màn hình xử lý
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return const ProcessingdialogScreen();
                            },
                          );

                          // Xử lý từ chối hồ sơ
                          final deniedTime = DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now());

                          // Cập nhật vào Firebase Realtime Database
                          FirebaseDatabase.instance.ref().child('files').child(widget.fileId).update({
                            'approvedtime': deniedTime,
                            'status': 'denied',
                            'comment_admin': commentDenied, // Thêm lý do từ chối vào đây
                          });

                          // Cập nhật vào Firebase Realtime Database notifications
                          FirebaseDatabase.instance.ref().child('notifications').child(widget.fileId).update({
                            widget.nameCreated: {
                              'message': 'Hồ sơ ${widget.name} của bạn đã bị từ chối bởi ${widget.approvedName} vào $deniedTime. Lý do: $commentDenied',
                              'isRead': false,
                            }
                          });

                          Future.delayed(const Duration(seconds: 2), () {
                            Navigator.of(context).popUntil((route) => route.isFirst); // Đóng tất cả dialog
                          });
                        } else {
                          // Hiển thị thông báo nếu lý do không được nhập
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập lý do từ chối.')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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

  void _deleteFile() async {
    // Hiển thị hộp thoại xử lý
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const ProcessingdialogScreen(); // Có thể sử dụng một màn hình xử lý nếu có
      },
    );

    // Xóa hồ sơ từ Firebase
    await FirebaseDatabase.instance.ref().child('files').child(widget.fileId).remove();

    // Xóa thông báo liên quan đến hồ sơ nếu có
    await FirebaseDatabase.instance.ref().child('notifications').child(widget.fileId).remove();

    // Đợi một chút để cập nhật UI
    await Future.delayed(const Duration(seconds: 2));

    // Đóng hộp thoại và quay về màn hình trước đó
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
  void _confirmDeleteFile() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xoá hồ sơ'),
          content: const Text('Bạn có chắc chắn muốn xóa hồ sơ này không?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng hộp thoại nếu người dùng chọn "Hủy"
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng hộp thoại xác nhận
                _deleteFile(); // Gọi hàm xóa hồ sơ
              },
              child: const Text('Xóa'),
            ),
          ],
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
}
