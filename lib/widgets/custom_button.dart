import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool loading;
  final Color? backgroundColor; // (MỚI) Thêm tham số màu nền
  final Color? foregroundColor; // (MỚI) Thêm tham số màu chữ/icon

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
    this.backgroundColor, // (MỚI)
    this.foregroundColor, // (MỚI)
  });

  @override
  Widget build(BuildContext context) {
    // (MỚI) Lấy màu từ tham số, nếu không có thì dùng màu mặc định từ Theme
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.primary;
    final fgColor = foregroundColor ?? Colors.white; // Mặc định chữ trắng

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor, // (CẬP NHẬT) Dùng màu đã chọn
        foregroundColor: fgColor, // (MỚI) Dùng màu chữ đã chọn
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        // (MỚI) Sử dụng style từ ElevatedButtonThemeData nếu có
        textStyle: Theme.of(context).elevatedButtonTheme.style?.textStyle?.resolve({}),
      ),
      onPressed: loading ? null : onPressed,
      child: loading
          ? CircularProgressIndicator(color: fgColor) // Dùng màu chữ cho loading
          : Text(text), // Không cần TextStyle nữa vì đã có trong theme/foregroundColor
    );
  }
}