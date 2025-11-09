// widgets/feature_button.dart (FILE MỚI - TÙY CHỌN)

import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class FeatureButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const FeatureButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.lightRedAccent,
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}