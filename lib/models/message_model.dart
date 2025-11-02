class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'].toString(),
      senderId: json['sender_id'].toString(),
      senderName: json['sender_name'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
