// (File mới: models/notification_model.dart)
// Dựa trên class NotificationOut của bạn

class NotificationModel {
  final int notificationId;
  final int userId;
  final String message;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.message,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['created_at']);
    } catch (e) {
      parsedDate = DateTime.now(); // Lỗi thì dùng ngày giờ hiện tại
    }

    return NotificationModel(
      notificationId: json['notification_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      message: json['message'] ?? 'Không có nội dung',
      createdAt: parsedDate,
    );
  }
}