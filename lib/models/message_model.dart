class MessageModel {
  final int messageId;
  final int userId;
  final String content;
  final DateTime timestamp;
  final String fullName; // Tên người gửi

  MessageModel({
    required this.messageId,
    required this.userId,
    required this.content,
    required this.timestamp,
    required this.fullName,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['message_id'],
      userId: json['user_id'],
      content: json['content'] ?? '',
      // Xử lý timestamp từ ISO 8601 string
      timestamp: DateTime.parse(json['timestamp']),
      fullName: json['full_name'] ?? 'Ẩn danh',
    );
  }
}