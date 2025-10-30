import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/invitation_model.dart';
import '../core/api_config.dart';
import 'auth_provider.dart';

class InvitationProvider extends ChangeNotifier {
  final AuthProvider auth;
  InvitationProvider(this.auth);

  List<InvitationModel> _invitations = [];
  List<InvitationModel> get invitations => _invitations;

  Future<void> fetchInvitations() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/invitations/');

    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${auth.token}'},
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      _invitations = data.map((e) => InvitationModel.fromJson(e)).toList();
      notifyListeners();
    } else {
      _invitations = [];
      notifyListeners();
      throw Exception('Không thể tải danh sách lời mời');
    }
  }

  Future<void> replyToInvitation(
      int invitationId, int groupId, String reply) async {
    final url = Uri.parse(
        '${ApiConfig.baseUrl}/invitations/reply_invitations/$invitationId?group_id=$groupId&reply=$reply');

    final res = await http.put(
      url,
      headers: {'Authorization': 'Bearer ${auth.token}'},
    );

    if (res.statusCode == 200) {
      _invitations.removeWhere((inv) => inv.invitationId == invitationId);
      notifyListeners();
    } else {
      throw Exception('Trả lời lời mời thất bại');
    }
  }

  // (MỚI) Hàm dọn dẹp khi logout
  void clearInvitations() {
    _invitations = [];
    notifyListeners();
  }
}