import 'dart:convert';
import 'dart:io'; // (MỚI) Import 'dart:io'
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_config.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _fullName;
  String? _account;
  String? _avatarUrl; // (MỚI) Thêm trường avatar

  String? get token => _token;
  String? get fullName => _fullName;
  String? get account => _account;
  String? get avatarUrl => _avatarUrl; // (MỚI) Thêm getter
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
        _avatarUrl = data['avatar_url']; // (MỚI) Lấy avatar_url từ API
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
  
  // (MỚI) Hàm tải avatar user lên
  Future<void> uploadAvatar(File imageFile) async {
    if (_token == null) throw Exception("Chưa đăng nhập");

    final url = Uri.parse('${ApiConfig.baseUrl}/auth/me/avatar');
    final request = http.MultipartRequest('POST', url);
    
    // Thêm header
    request.headers['Authorization'] = 'Bearer $_token';
    
    // Thêm file
    request.files.add(
      await http.MultipartFile.fromPath(
        'file', // (Tên trường này phải khớp với FastAPI)
        imageFile.path,
      ),
    );

    // Gửi request
    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);

    if (res.statusCode == 200) {
      // Cập nhật lại avatar_url trong state
      final data = jsonDecode(res.body);
      _avatarUrl = data['avatar_url'];
      notifyListeners();
    } else {
      throw Exception('Tải ảnh thất bại: ${res.body}');
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

        // Lấy thông tin user ngay sau khi login (sẽ lấy cả avatar)
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

    // Sẽ lấy cả avatar
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
    _avatarUrl = null; // (MỚI) Xóa avatar khi logout
    notifyListeners();
    print('🚪 Đã đăng xuất');
  }
}