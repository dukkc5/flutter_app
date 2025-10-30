class InvitationModel {
  final int invitationId;
  final int groupId;
  final String title; // API trả về "title" chứa tất cả thông tin

  InvitationModel({
    required this.invitationId,
    required this.groupId,
    required this.title,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      invitationId: json['id'], // Sửa từ 'invitation_id' -> 'id'
      groupId: json['group_id'],
      title: json['title'] ?? 'Lời mời không có tiêu đề', // Sửa lại
    );
  }
}