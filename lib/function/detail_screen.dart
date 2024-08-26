import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final String name;
  final String description;
  final String status;
  final String datetime;
  final Map<String, String?> originalFiles;
  final String nameCreated;
  final String author; // New property

  const ProductDetailScreen({
    required this.name,
    required this.description,
    required this.status,
    required this.datetime,
    required this.originalFiles,
    required this.nameCreated,
    required this.author, // Initialize the new property
    Key? key,
  }) : super(key: key);

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
        actions: author == 'user'
            ? [
          Padding(
            padding: const EdgeInsets.only(right: 10.0), // Add 10dp padding to the right
            child: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // Handle product deletion
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
            Text('Tiêu đề: $name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Mô tả: $description\n',
                    style: const TextStyle(fontSize: 16),
                  ),
                  TextSpan(
                    text: 'Trạng thái: ${_getStatusText(status)}\n',
                    style: const TextStyle(fontSize: 16),
                  ),
                  TextSpan(
                    text: 'Ngày tạo hồ sơ: $datetime\n',
                    style: const TextStyle(fontSize: 16),
                  ),
                  TextSpan(
                    text: 'Người tạo: $nameCreated\n',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              style: const TextStyle(height: 1.5), // Adjust line spacing if needed
            ),
            Text('Biên bản gốc bao gồm', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...originalFiles.entries.map((entry) {
              return Text('${entry.value ?? 'Không có dữ liệu'} ${entry.key}', style: const TextStyle(fontSize: 16));
            }).toList(),
            const SizedBox(height: 10),
            // Conditional button display based on author
            if (author == 'admin') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Handle approval logic
                    },
                    child: const Text('Phê duyệt hồ sơ'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Handle rejection logic
                    },
                    child: const Text('Từ chối hồ sơ'),
                  ),
                ],
              ),
            ] else if (author == 'manager') ...[
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Handle review completion logic
                  },
                  child: const Text('Đã Soát Xét Hồ Sơ'),
                ),
              ),
            ] else if (author == 'stamper') ...[
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Handle stamping logic
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
}
