import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyTaskModel {
  final int assignmentId;
  final int groupId; // KHÔI PHỤC: Thêm lại groupId
  final String taskTitle;
  final String groupName;
  final String? comment;
  final String? status; 
  final DateTime deadline;

  MyTaskModel({
    required this.assignmentId,
    required this.groupId, // KHÔI PHỤC
    required this.taskTitle,
    required this.groupName,
    this.comment,
    this.status,
    required this.deadline,
  });

  factory MyTaskModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDeadline;
    if (json['deadline'] != null) {
      try {
        parsedDeadline = DateTime.parse(json['deadline']);
      } catch (e) {
        print('Error parsing MyTask deadline: ${json['deadline']} - $e');
        parsedDeadline = DateTime.now().add(const Duration(days: 1)); 
      }
    } else {
      parsedDeadline = DateTime.now().add(const Duration(days: 1)); 
    }

    return MyTaskModel(
      assignmentId: json['assignment_id'] ?? 0,
      groupId: json['group_id'] ?? 0, // ĐỌC LẠI groupId từ JSON
      taskTitle: json['task_title'] ?? 'N/A',
      groupName: json['group_name'] ?? 'N/A',
      comment: json['comment'],
      status: json['status'], 
      deadline: parsedDeadline,
    );
  }
}

// --- HELPER FUNCTIONS ---
String formatMyTaskDate(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

Color getMyTaskStatusColor(String? status) {
   switch (status) {
    case 'hoàn thành':
      return Colors.green.shade50;
    case 'trễ hạn':
      return Colors.red.shade50;
    case 'đang làm':
      return Colors.blue.shade50;
    case 'pending':
      return Colors.yellow.shade50;
    default:
      return Colors.grey.shade100;
  }
}