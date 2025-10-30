import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';
import '../models/assignment_model.dart';
import '../models/my_task_model.dart'; // (MỚI) Import MyTaskModel
import '../core/api_config.dart';
import 'auth_provider.dart';

class TaskProvider extends ChangeNotifier {
  final AuthProvider auth;
  TaskProvider(this.auth);

  List<TaskModel> _groupTasks = [];
  List<TaskModel> get groupTasks => _groupTasks;

  List<AssignmentModel> _assignments = [];
  List<AssignmentModel> get assignments => _assignments;
  
  // (MỚI) State cho nhiệm vụ của user hiện tại
  List<MyTaskModel> _myTasks = [];
  List<MyTaskModel> get myTasks => _myTasks;

  // Lấy danh sách task của một nhóm
  Future<void> fetchTasksForGroup(int groupId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/tasks/?group_id=$groupId');
    
    final res = await http.get(url, headers: {
      'Authorization': 'Bearer ${auth.token}',
    });

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      _groupTasks = data.map((e) => TaskModel.fromJson(e)).toList();
      notifyListeners();
    } else {
      _groupTasks = [];
      notifyListeners();
      print('Lỗi fetchTasksForGroup: ${res.body}');
      throw Exception('Không thể tải nhiệm vụ của nhóm (Code: ${res.statusCode})');
    }
  }

  // Lấy danh sách assignments của một task lớn
  Future<void> fetchAssignmentsForTask(int taskId) async {
    // API: GET /list/{task_id} (Theo code backend bạn gửi)
    final url = Uri.parse('${ApiConfig.baseUrl}/tasks_assignments/list/$taskId'); 

    final res = await http.get(url, headers: {
      'Authorization': 'Bearer ${auth.token}',
    });

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      _assignments = data.map((e) => AssignmentModel.fromJson(e)).toList();
      notifyListeners();
    } else {
      _assignments = [];
      notifyListeners();
       print('Lỗi fetchAssignmentsForTask: ${res.body}');
      throw Exception('Không thể tải danh sách giao việc (Code: ${res.statusCode})');
    }
  }

  // Dọn dẹp state assignments
  void clearAssignments() {
    _assignments = [];
    notifyListeners();
  }

  // (MỚI) Lấy danh sách nhiệm vụ của user hiện tại
  Future<void> fetchMyTasks() async {
    // API: GET /tasks_assignments/my-tasks
    final url = Uri.parse('${ApiConfig.baseUrl}/tasks_assignments/my-tasks'); // Giả sử cần /
    
    final res = await http.get(url, headers: {
      'Authorization': 'Bearer ${auth.token}',
    });

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      _myTasks = data.map((e) => MyTaskModel.fromJson(e)).toList();
      notifyListeners();
    } else {
      _myTasks = [];
      notifyListeners();
      print('Lỗi fetchMyTasks: ${res.body}');
      throw Exception('Không thể tải nhiệm vụ cá nhân (Code: ${res.statusCode})');
    }
  }

  // (MỚI) Dọn dẹp state nhiệm vụ của tôi khi logout
  void clearMyTasks() {
    _myTasks = [];
    notifyListeners();
  }

  // Tạo task mới (Task Lớn)
  Future<void> createTask(int groupId, String title, String description,
      DateTime deadline, String status) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/tasks/');

    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${auth.token}',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'group_id': groupId,
        'title': title,
        'description': description,
        'deadline': deadline.toIso8601String(),
        'status': status,
      }),
    );

    if (res.statusCode == 201) {
      await fetchTasksForGroup(groupId);
    } else {
      print('Lỗi tạo task: ${res.body}');
      throw Exception('Tạo nhiệm vụ thất bại');
    }
  }

  // Xóa task (Task Lớn)
  Future<void> deleteTask(int groupId, int taskId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/tasks/$taskId?group_id=$groupId');

    final res = await http.delete(
      url,
      headers: {'Authorization': 'Bearer ${auth.token}'},
    );

    if (res.statusCode == 200 || res.statusCode == 204) {
      _groupTasks.removeWhere((task) => task.id == taskId);
      notifyListeners();
    } else {
      print('Lỗi xóa task: ${res.body}');
      throw Exception('Xóa nhiệm vụ thất bại');
    }
  }

  // Gán task con (Assignment)
  Future<void> assignTaskNew(int groupId, int taskId, int userId, String comment, DateTime deadline) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/tasks_assignments/assign'); 
    
    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${auth.token}',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'task_id': taskId,
        'user_id': userId, 
        'comment': comment,
        'deadline': deadline.toIso8601String(),
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      await fetchAssignmentsForTask(taskId);
      await fetchTasksForGroup(groupId);
    } else {
      print('Lỗi Gán Task mới: ${res.body}');
      throw Exception('Gán nhiệm vụ thất bại (Code: ${res.statusCode})');
    }
  }

  // Xóa assignment
  Future<void> deleteAssignment(int assignmentId, int taskId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/tasks_assignments/$assignmentId');

    final res = await http.delete(
      url,
      headers: {'Authorization': 'Bearer ${auth.token}'},
    );

     if (res.statusCode == 200 || res.statusCode == 204) {
      await fetchAssignmentsForTask(taskId);
    } else {
      print('Lỗi Xóa Assignment: ${res.body}');
      throw Exception('Hủy giao việc thất bại (Code: ${res.statusCode})');
    }
  }

  // Cập nhật assignment (comment, deadline, status)
  Future<void> updateAssignment(
    int assignmentId,
    int taskId, // Cần để refresh list
    String comment,
    DateTime deadline,
    String status,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/tasks_assignments/$assignmentId');

    final res = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer ${auth.token}',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'comment': comment,
        'deadline': deadline.toIso8601String(),
        'status': status,
      }),
    );

    if (res.statusCode == 200) {
       await fetchAssignmentsForTask(taskId);
    } else {
      print('Lỗi Sửa Assignment: ${res.body}');
      throw Exception('Cập nhật giao việc thất bại (Code: ${res.statusCode})');
    }
  }


  // Cập nhật thông tin task lớn
  Future<void> updateTask(
    int groupId,
    int taskId,
    String title,
    String description,
    String status,
    DateTime deadline,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/tasks/$taskId?group_id=$groupId');
    
    final res = await http.put(
      url,
      headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'status': status,
        'deadline': deadline.toIso8601String(),
      }),
    );

    if (res.statusCode == 200) {
       await fetchTasksForGroup(groupId);
    } else {
      print('Lỗi sửa task (PUT): ${res.body}');
      throw Exception('Sửa nhiệm vụ thất bại (Code: ${res.statusCode})');
    }
  }

  // Dọn dẹp state task của nhóm
  void clearGroupTasks() {
    _groupTasks = [];
    notifyListeners();
  }
}

