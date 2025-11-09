// models/member_model.dart (Full code)

class MemberModel {
  final int userId;
  final String fullName;
  final String account;
  final String role;
  final String? avatarUrl; // (MỚI) Thêm avatar

  MemberModel({
    required this.userId,
    required this.fullName,
    required this.account,
    required this.role,
    this.avatarUrl, // (MỚI)
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      userId: json['user_id'],
      fullName: json['full_name'] ?? 'Không có tên',
      account: json['account'] ?? 'Không có tài khoản',
      role: json['role'] ?? 'Không rõ',
      avatarUrl: json['avatar_url'], // (MỚI) Đọc từ JSON
    );
  }
}