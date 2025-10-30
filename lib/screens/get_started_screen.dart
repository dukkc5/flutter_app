import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_colors.dart';
import '../main.dart'; // Để import AuthOrHome
import '../widgets/custom_button.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  Future<void> _onGetStarted(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenGetStarted', true);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthOrHome()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // (MỚI) Thêm một Icon lớn cho đẹp
            const Icon(
              Icons.group_work,
              size: 120,
              color: AppColors.primary,
            ),
            const SizedBox(height: 40),

            // (MỚI) Tiêu đề
            Text(
              'Chào mừng đến với\nPTIT TEAM',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // (MỚI) Mô tả
            Text(
              'Quản lý công việc, nhóm, và các dự án của bạn một cách hiệu quả và đơn giản.',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 60),

            // (MỚI) Nút Bắt đầu
            CustomButton(
              text: 'Bắt đầu',
              onPressed: () => _onGetStarted(context),
            ),
          ],
        ),
      ),
    );
  }
}