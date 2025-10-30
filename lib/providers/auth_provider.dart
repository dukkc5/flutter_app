import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_config.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  // (MỚI) Thêm biến lưu thông tin user
  String? _fullName;
  String? _account;

  String? get token => _token;
  String? get fullName => _fullName;
  String? get account => _account;
  bool get isAuthenticated => _token != null;

  // (MỚI) Hàm gọi API /auth/me
  Future<void> fetchCurrentUser() async {
    if (_token == null) return; // Không gọi nếu chưa login

    final url = Uri.parse('${ApiConfig.baseUrl}/auth/me'); // Thêm /
    try {
      final res = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _fullName = data['full_name'];
        _account = data['account'];
        notifyListeners(); // Thông báo để UI cập nhật
      } else {
        // Có thể token hết hạn, nên logout
        print('Lỗi fetchCurrentUser: ${res.body}');
        await logout(); // Tự động logout nếu token không hợp lệ
      }
    } catch (e) {
      print('Lỗi mạng fetchCurrentUser: $e');
      // Xử lý lỗi mạng nếu cần
    }
  }

  Future<void> login(String account, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login'); // Thêm /
    final res = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'account': account, 'password': password}));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _token = data['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _token!);
      
      // (CẬP NHẬT) Gọi fetchCurrentUser ngay sau khi login thành công
      await fetchCurrentUser();
      
      notifyListeners(); // Notify sau khi có cả token và user info
    } else {
      throw Exception('Đăng nhập thất bại');
    }
  }

  Future<void> register(
      String fullname, String account, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/register'); // Thêm /
    final res = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {
              "account": account,
              "password": password,
              "full_name": fullname})); // Sửa acccount

    if (res.statusCode != 201) {
      throw Exception('Đăng ký thất bại');
    }
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('access_token')) return;
    _token = prefs.getString('access_token');
    
    // (CẬP NHẬT) Gọi fetchCurrentUser khi auto login
    if (_token != null) {
      await fetchCurrentUser();
    }
    
    notifyListeners(); // Notify sau khi có cả token và user info (hoặc chỉ token nếu fetch lỗi)
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    _token = null;
    // (CẬP NHẬT) Xóa thông tin user khi logout
    _fullName = null;
    _account = null;
    notifyListeners();
  }
}