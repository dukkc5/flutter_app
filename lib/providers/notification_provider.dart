// providers/notification_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';

class NotificationProvider extends ChangeNotifier {
  final AuthProvider auth;
  NotificationProvider(this.auth);

  List<NotificationModel> _notifications = [];
  
  // (SỬA) "Số chưa đọc" chính là tổng số thông báo
  int get unreadCount => _notifications.length;
  List<NotificationModel> get notifications => _notifications;


  /// (API 1) Gọi GET /notifications/
  Future<void> fetchNotifications() async {
    if (auth.token == null) return;
    
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/notifications/');
      final res = await http.get(url, headers: {
        'Authorization': 'Bearer ${auth.token}',
      });

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        _notifications = data.map((e) => NotificationModel.fromJson(e)).toList();
      } else {
        _notifications = [];
      }
    } catch (e) {
      print("Lỗi fetchNotifications: $e");
      _notifications = [];
    }
    notifyListeners();
  }

  /// (API 2) Gọi DELETE /notifications/
  Future<void> deleteAllNotifications() async {
    if (auth.token == null) throw Exception("Chưa đăng nhập");
    
    // Cập nhật UI trước (cho nhanh)
    _notifications = [];
    notifyListeners();
    
    // Gọi API trong nền
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/notifications/');
      final res = await http.delete(url, headers: {
        'Authorization': 'Bearer ${auth.token}',
      });
      
      if (res.statusCode != 204) {
         // Nếu lỗi, fetch lại (dù lúc này list cũng rỗng)
         await fetchNotifications();
      }
    } catch (e) {
      print("Lỗi deleteAllNotifications: $e");
    }
  }

  /// Dọn dẹp khi logout
  void clearNotifications() {
    _notifications = [];
    notifyListeners();
  }
}