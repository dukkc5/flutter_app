
class AssignmentModel {
  final int assignmentId;
  final int taskId;
  final int assignerId;
  final String fullName;
  final String? comment;
  final String? status;
  final DateTime? deadline;
  final String? attachmentUrl; // (MỚI) Thêm trường này

  AssignmentModel({
    required this.assignmentId,
    required this.taskId,
    required this.assignerId,
    required this.fullName,
    this.comment,
    this.status,
    this.deadline,
    this.attachmentUrl, // (MỚI) Thêm vào constructor
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDeadline;
    if (json['deadline'] != null) {
      try {
        parsedDeadline = DateTime.parse(json['deadline']);
      } catch (e) {
        parsedDeadline = null;
      }
    }

    return AssignmentModel(
      assignmentId: json['assignment_id'],
      taskId: json['task_id'],
      assignerId: json['assigner_id'], // Sửa lại key
      fullName: json['full_name'] ?? 'N/A',
      comment: json['comment'],
      status: json['status'],
      deadline: parsedDeadline,
      attachmentUrl: json['attachment_url'], // (MỚI) Lấy attachment_url từ JSON
    );
  }
}

