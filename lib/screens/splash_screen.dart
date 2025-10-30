import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'get_started_screen.dart';
import '../main.dart'; // Để import AuthOrHome

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    // Đợi 1 chút để logo/splash hiển thị
    await Future.delayed(const Duration(seconds: 1));

    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenGetStarted = prefs.getBool('hasSeenGetStarted') ?? false;

    if (mounted) {
      if (hasSeenGetStarted) {
        // Nếu đã xem, đi thẳng vào logic đăng nhập
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthOrHome()),
        );
      } else {
        // Nếu lần đầu, đi tới màn hình Get Started
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GetStartedScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bạn có thể thêm logo của mình ở đây
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}