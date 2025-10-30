import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/group_model.dart';
import '../models/member_model.dart';
import 'auth_provider.dart';

class GroupProvider extends ChangeNotifier {
  final AuthProvider auth;
  GroupProvider(this.auth);

  List<GroupModel> _groups = [];
  List<GroupModel> get groups => _groups;

  List<MemberModel> _members = [];
  List<MemberModel> get members => _members;

   String? _currentGroupRole; // State mới: 'leader' hoặc 'member'
  String? get currentGroupRole => _currentGroupRole;

  Future<void> fetchGroups() async {
    // (SỬA) Thêm /
    final url = Uri.parse('${ApiConfig.baseUrl}/groups/');
    final res = await http.get(url, headers: {
      'Authorization': 'Bearer ${auth.token}',
    });

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      _groups = data.map((e) => GroupModel.fromJson(e)).toList();
      notifyListeners();
    } else {
      throw Exception('Không thể tải danh sách nhóm');
    }
  }
  Future<void> fetchUserRoleInGroup(int groupId) async {
    // API: GET /groups/current_role/{group_id}
    final url = Uri.parse('${ApiConfig.baseUrl}/groups/current_role/$groupId'); 

    final res = await http.get(url, headers: {
      'Authorization': 'Bearer ${auth.token}',
    });

    if (res.statusCode == 200) {
      // API trả về string trực tiếp (ví dụ: "leader" hoặc "member")
      final data = jsonDecode(res.body);
      // Data là string, ta phải dùng toString().toLowerCase()
      _currentGroupRole = data.toString().toLowerCase(); 
    } else {
      _currentGroupRole = 'member'; // Mặc định là member nếu không lấy được
      print('Lỗi lấy role: ${res.body}');
    }
    notifyListeners();
  }

  Future<void> fetchMembersForGroup(int groupId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/groups/members?group_id=$groupId');

    final res = await http.get(url, headers: {
      'Authorization': 'Bearer ${auth.token}',
    });

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      _members = data.map((e) => MemberModel.fromJson(e)).toList();
      notifyListeners();
    } else {
      _members = [];
      notifyListeners();
      throw Exception(
          'Không thể tải danh sách thành viên (Code: ${res.statusCode})');
    }
  }

  void clearMembers() {
    _members = [];
    notifyListeners();
  }
   void clearGroupRole() {
    _currentGroupRole = null;
    notifyListeners();
  }

  Future<void> fetchGroupDetail() async {
    // (Trống)
  }

  Future<void> inviteMember(int groupId, String account) async {
    // (SỬA) Thêm /
    final url = Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/members');

    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${auth.token}',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'account': account}),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      try {
        final error = jsonDecode(res.body);
        throw Exception(error['detail'] ?? 'Mời thành viên thất bại');
      } catch (e) {
        throw Exception('Mời thành viên thất bại (Code: ${res.statusCode})');
      }
    }
  }

  Future<void> deleteMember(int groupId, String account) async {
    // (SỬA) Thêm /
    final url =
        Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/members/$account');

    final res = await http.delete(
      url,
      headers: {'Authorization': 'Bearer ${auth.token}'},
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      print('Lỗi Xóa Member: ${res.body}');
      throw Exception('Xóa thành viên thất bại');
    }
    await fetchMembersForGroup(groupId);
  }

  Future<void> promoteMember(int groupId, int userId) async {
    // (SỬA) Thêm /
    final url =
        Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/members/$userId');

    final res = await http.post(url,
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'account': 'placeholder_account'}));

    if (res.statusCode != 200 && res.statusCode != 201) {
      print('Lỗi Promote Member: ${res.body}');
      throw Exception('Chuyển quyền thất bại');
    }
    await fetchMembersForGroup(groupId);
    
  }

  void clearAllGroups() {
    _groups = [];
    _members = [];
    _currentGroupRole = null; // Dọn dẹp cả Role
    notifyListeners();
  }

  // (MỚI) Hàm Tạo Nhóm
  Future<void> createGroup(String groupName, String description) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/groups/');

    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${auth.token}',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'group_name': groupName,
        'description': description,
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      // Nếu thành công, tải lại danh sách nhóm
      await fetchGroups();
    } else {
      print('Lỗi Tạo Nhóm: ${res.body}');
      throw Exception('Tạo nhóm thất bại');
    }
  }

  // (MỚI) Hàm Xóa Nhóm
  Future<void> deleteGroup(int groupId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/groups/$groupId');

    final res = await http.delete(
      url,
      headers: {'Authorization': 'Bearer ${auth.token}'},
    );

    if (res.statusCode == 200 || res.statusCode == 204) {
      // Nếu thành công, tải lại danh sách nhóm
      await fetchGroups();
    } else {
      print('Lỗi Xóa Nhóm: ${res.body}');
      throw Exception('Xóa nhóm thất bại');
    }
  }
  // (MỚI) Hàm Rời Nhóm
  Future<void> leaveGroup(int groupId) async {
    // API: DELETE /groups/leave?group_id={group_id}
    // Check if API requires trailing slash based on your FastAPI setup
    final url = Uri.parse('${ApiConfig.baseUrl}/groups/leave/$groupId'); // Assuming / needed

    final res = await http.delete(
      url,
      headers: {'Authorization': 'Bearer ${auth.token}'},
    );

    if (res.statusCode == 200 || res.statusCode == 204) {
      // If successful, refresh the group list on the previous screen
      await fetchGroups();
    } 
    else {
      print('Lỗi Rời Nhóm: ${res.body}');
      throw Exception('Rời nhóm thất bại (Code: ${res.statusCode})');
    }
  }
  
}