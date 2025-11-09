import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/group_model.dart';
import '../models/member_model.dart';
import 'auth_provider.dart';
import 'dart:io'; // (MỚI) Import
import 'package:http_parser/http_parser.dart'; // (MỚI) Import

enum GroupFilter { all, leader, member }

class GroupProvider extends ChangeNotifier {
  final AuthProvider auth;
  GroupProvider(this.auth);

  List<GroupModel> _allGroups = [];
  List<GroupModel> _filteredGroups = [];
  
  List<GroupModel> get groups => _filteredGroups; // Cho Tab "Nhóm" (đã lọc)
  List<GroupModel> get chatGroups => _allGroups;  // Cho Tab "Chat" (đầy đủ)

  GroupFilter _currentFilter = GroupFilter.all;
  GroupFilter get currentFilter => _currentFilter;

  List<MemberModel> _members = [];
  List<MemberModel> get members => _members;

  String? _currentGroupRole;
  String? get currentGroupRole => _currentGroupRole;

  void _applyFilter() {
    if (_currentFilter == GroupFilter.leader) {
      _filteredGroups = _allGroups.where((g) => g.myRole == 'leader').toList();
    } else if (_currentFilter == GroupFilter.member) {
      _filteredGroups = _allGroups.where((g) => g.myRole == 'member').toList();
    } else {
      _filteredGroups = List.from(_allGroups);
    }
    notifyListeners();
  }

  void setFilter(GroupFilter filter) {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    _applyFilter();
  }

  Future<void> fetchGroups() async {
    if (auth.token == null) return;
    
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/groups/'); // API duy nhất
      final headers = {'Authorization': 'Bearer ${auth.token}'};
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        
        // DÒNG NÀY ĐÃ LẤY AVATAR URL (và mọi thứ khác)
        _allGroups = data.map((e) => GroupModel.fromJson(e)).toList();
        
        _allGroups.sort((a, b) {
            if (a.lastMessageTimestamp == null && b.lastMessageTimestamp == null) return 0;
            if (a.lastMessageTimestamp == null) return 1;
            if (b.lastMessageTimestamp == null) return -1;
            return b.lastMessageTimestamp!.compareTo(a.lastMessageTimestamp!);
        });
        
      } else {
        print("Lỗi tải nhóm: ${response.body}");
        _allGroups = [];
      }
      
      _applyFilter();
      
    } catch (e) {
      print("Lỗi mạng khi fetchGroups: $e");
      _allGroups = [];
      _applyFilter();
      throw Exception('Không thể tải danh sách nhóm');
    }
  }
  
  Future<void> fetchUserRoleInGroup(int groupId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/groups/current_role/$groupId'); 
    final res = await http.get(url, headers: {'Authorization': 'Bearer ${auth.token}'});
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _currentGroupRole = data.toString().toLowerCase(); 
    } else {
      _currentGroupRole = 'member';
      print('Lỗi lấy role: ${res.body}');
    }
    notifyListeners();
  }

  Future<void> fetchMembersForGroup(int groupId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/groups/members?group_id=$groupId');
    final res = await http.get(url, headers: {'Authorization': 'Bearer ${auth.token}'});
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      _members = data.map((e) => MemberModel.fromJson(e)).toList();
      notifyListeners();
    } else {
      _members = [];
      notifyListeners();
      throw Exception('Không thể tải danh sách thành viên (Code: ${res.statusCode})');
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
    final url = Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/members');
    final res = await http.post(
      url,
      headers: {'Authorization': 'Bearer ${auth.token}', 'Content-Type': 'application/json'},
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
    final url = Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/members/$account');
    final res = await http.delete(url, headers: {'Authorization': 'Bearer ${auth.token}'});
    if (res.statusCode != 200 && res.statusCode != 204) {
      print('Lỗi Xóa Member: ${res.body}');
      throw Exception('Xóa thành viên thất bại');
    }
    await fetchMembersForGroup(groupId);
  }

  Future<void> promoteMember(int groupId, int userId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/members/$userId');
    final res = await http.post(url,
        headers: {'Authorization': 'Bearer ${auth.token}', 'Content-Type': 'application/json'},
        body: jsonEncode({'account': 'placeholder_account'}));
    if (res.statusCode != 200 && res.statusCode != 201) {
      print('Lỗi Promote Member: ${res.body}');
      throw Exception('Chuyển quyền thất bại');
    }
    await fetchMembersForGroup(groupId);
  }

  @override
  void clearAllGroups() {
    _allGroups = [];
    _filteredGroups = [];
    _members = [];
    _currentGroupRole = null;
    notifyListeners();
  }

  Future<void> createGroup(String groupName, String description) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/groups/');
    final res = await http.post(
      url,
      headers: {'Authorization': 'Bearer ${auth.token}', 'Content-Type': 'application/json'},
      body: jsonEncode({'group_name': groupName, 'description': description}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      await fetchGroups();
    } else {
      print('Lỗi Tạo Nhóm: ${res.body}');
      throw Exception('Tạo nhóm thất bại');
    }
  }

  Future<void> deleteGroup(int groupId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/groups/$groupId');
    final res = await http.delete(url, headers: {'Authorization': 'Bearer ${auth.token}'});
    if (res.statusCode == 200 || res.statusCode == 204) {
      await fetchGroups();
    } else {
      print('Lỗi Xóa Nhóm: ${res.body}');
      throw Exception('Xóa nhóm thất bại');
    }
  }
 
  Future<void> leaveGroup(int groupId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/groups/leave/$groupId');
    final res = await http.delete(url, headers: {'Authorization': 'Bearer ${auth.token}'});
    if (res.statusCode == 200 || res.statusCode == 204) {
      await fetchGroups();
    } 
    else {
      print('Lỗi Rời Nhóm: ${res.body}');
      throw Exception('Rời nhóm thất bại (Code: ${res.statusCode})');
    }
  }
   Future<void> editGroup(int groupId, String groupName, String description) async {
    if (auth.token == null) throw Exception("Chưa đăng nhập");

    final url = Uri.parse('${ApiConfig.baseUrl}/groups/$groupId');
    final res = await http.patch( // (MỚI) Dùng PATCH
      url,
      headers: {
        'Authorization': 'Bearer ${auth.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'group_name': groupName,
        'description': description,
      }),
    );

    if (res.statusCode == 200) {
      // Thành công, tải lại toàn bộ danh sách
      await fetchGroups();
    } else {
      print('Lỗi Sửa Nhóm: ${res.body}');
      throw Exception('Sửa nhóm thất bại');
    }
  }

  // (MỚI) Hàm upload Avatar nhóm
  Future<void> uploadGroupAvatar(int groupId, File imageFile) async {
    if (auth.token == null) throw Exception("Chưa đăng nhập");

    final url = Uri.parse('${ApiConfig.baseUrl}/groups/$groupId/avatar');
    final request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer ${auth.token}';
    
    // Thêm file
    request.files.add(
      await http.MultipartFile.fromPath(
        'file', // Phải khớp với 'file: UploadFile = File(...)'
        imageFile.path,
        // (Tùy chọn) Thêm content type
        contentType: MediaType('image', imageFile.path.split('.').last),
      ),
    );

    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);

    if (res.statusCode == 200) {
      // Thành công, tải lại toàn bộ danh sách
      await fetchGroups();
    } else {
      print('Lỗi Upload Avatar Nhóm: ${res.body}');
      throw Exception('Tải ảnh lên thất bại: ${res.body}');
    }
  }
}
// (MỚI) Hàm sửa Tên/Mô tả nhóm
