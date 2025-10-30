class MemberModel {
  final int userId;
  final String fullName;
  final String account;
  final String role;

  MemberModel({
    required this.userId,
    required this.fullName,
    required this.account,
    required this.role,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      userId: json['user_id'],
      fullName: json['full_name'] ?? 'Không có tên',
      account: json['account'] ?? 'Không có tài khoản',
      role: json['role'] ?? 'Không rõ',
    );
  }
}