import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_config.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _fullName;
  String? _account;

  String? get token => _token;
  String? get fullName => _fullName;
  String? get account => _account;
  bool get isAuthenticated => _token != null;

  /// Lấy thông tin user hiện tại từ token
  Future<void> fetchCurrentUser() async {
    if (_token == null) return;

    final url = Uri.parse('${ApiConfig.baseUrl}/auth/me');
    try {
      final res = await http.get(url, headers: {
        'Authorization': 'Bearer $_token',
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _fullName = data['full_name'];
        _account = data['account'];
        print('✅ fetchCurrentUser thành công: $_fullName ($_account)');
        notifyListeners();
      } else {
        print('⚠️ fetchCurrentUser lỗi ${res.statusCode}: ${res.body}');
        await logout(); // token không hợp lệ
      }
    } catch (e) {
      print('❌ Lỗi mạng fetchCurrentUser: $e');
    }
  }

  /// Đăng nhập, trả về true nếu thành công
  Future<bool> login(String account, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'account': account, 'password': password}),
      );

      print('📩 [LOGIN] status: ${res.statusCode}, body: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _token = data['access_token'];

        if (_token == null || _token!.isEmpty) {
          print('⚠️ Token rỗng, login thất bại');
          return false;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', _token!);

        // Lấy thông tin user ngay sau khi login
        await fetchCurrentUser();

        notifyListeners();
        return true;
      } else {
        print('❌ Đăng nhập thất bại: ${res.body}');
        return false;
      }
    } catch (e) {
      print('💥 Lỗi mạng khi login: $e');
      return false;
    }
  }

  /// Đăng ký tài khoản
  Future<void> register(String fullname, String account, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/register');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "account": account,
        "password": password,
        "full_name": fullname,
      }),
    );

    print('📩 [REGISTER] status: ${res.statusCode}, body: ${res.body}');

    if (res.statusCode != 201) {
      throw Exception('Đăng ký thất bại: ${res.body}');
    }
  }

  /// Tự động đăng nhập nếu đã có token
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('access_token');

    if (savedToken == null || savedToken.isEmpty) {
      print('⚠️ Không có token trong SharedPreferences');
      return;
    }

    _token = savedToken;
    print('✅ Đã load token từ SharedPreferences: $_token');

    await fetchCurrentUser();
    notifyListeners();
  }

  /// Đăng xuất
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    _token = null;
    _fullName = null;
    _account = null;
    notifyListeners();
    print('🚪 Đã đăng xuất');
  }
}
