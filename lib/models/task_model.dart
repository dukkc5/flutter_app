class TaskModel {
  final int id;
  final String title;
  final String description;
  final String status;
  final DateTime deadline;
  final int? assigneeId; // ID người được gán (có thể null)
  final String? assigneeName; // Tên người được gán (có thể null)

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.deadline,
    this.assigneeId,
    this.assigneeName,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    // Kiểm tra và parse deadline an toàn
    DateTime parsedDeadline;
    if (json['deadline'] != null) {
      try {
        parsedDeadline = DateTime.parse(json['deadline']);
      } catch (e) {
        print('Error parsing deadline: ${json['deadline']} - $e');
        // Đặt deadline mặc định nếu parse lỗi (ví dụ: ngày mai)
        parsedDeadline = DateTime.now().add(const Duration(days: 1)); 
      }
    } else {
       // Đặt deadline mặc định nếu API không trả về
       parsedDeadline = DateTime.now().add(const Duration(days: 1)); 
    }

    return TaskModel(
      id: json['task_id'] ?? json['id'] ?? 0, // Cung cấp giá trị mặc định nếu null
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'đang làm',
      deadline: parsedDeadline,
      assigneeId: json['assignee_user_id'], // Giả định key từ API
      assigneeName: json['assignee_full_name'], // Giả định key từ API
    );
  }
}

