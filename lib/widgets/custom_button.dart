import 'package:flutter/material.dart';
import '../core/app_colors.dart'; // (MỚI) Import màu

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool loading;
  final Color? backgroundColor; 
  final Color? foregroundColor; 

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // (SỬA) Lấy màu từ tham số, nếu không có thì mặc định là Đỏ
    final bgColor = backgroundColor ?? AppColors.primary;
    // (SỬA) Lấy màu từ tham số, nếu không có thì mặc định là Trắng
    final fgColor = foregroundColor ?? AppColors.white; 

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor, // Dùng màu đỏ
        foregroundColor: fgColor, // Dùng màu trắng
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: Theme.of(context).elevatedButtonTheme.style?.textStyle?.resolve({}),
      ),
      onPressed: loading ? null : onPressed,
      child: loading
          ? CircularProgressIndicator(color: fgColor)
          : Text(text),
    );
  }
}