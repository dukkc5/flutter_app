import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // (CẦN IMPORT)
import 'dart:io'; // (CẦN IMPORT)

import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/invitation_provider.dart';
import '../providers/task_provider.dart';
import '../core/app_colors.dart';
import '../screens/login_screen.dart';

class PersonalTabView extends StatelessWidget {
  const PersonalTabView({super.key});

  // (MỚI) Hàm xử lý Logout
  Future<void> _handleLogout(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final invProvider = Provider.of<InvitationProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    // Dọn dẹp tất cả các provider
    groupProvider.clearAllGroups();
    invProvider.clearInvitations();
    taskProvider.clearMyTasks();

    await auth.logout();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // (MỚI) Hàm chọn và tải ảnh
  Future<void> _pickAndUploadImage(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ImagePicker picker = ImagePicker();
    
    // 1. Chọn ảnh
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return; // Người dùng hủy
    
    // 2. Tải lên
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tải ảnh lên...')),
      );
      
      // Gọi hàm uploadAvatar() trong AuthProvider
      await auth.uploadAvatar(File(image.path)); 
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật ảnh đại diện thành công!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải ảnh: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // (SỬA) Bật listen: true để UI tự cập nhật khi avatarUrl thay đổi
    final auth = Provider.of<AuthProvider>(context, listen: true);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          
          // (SỬA) Bọc CircleAvatar bằng GestureDetector
          GestureDetector(
            onTap: () {
              // (MỚI) Gọi hàm upload
              _pickAndUploadImage(context);
            },
            child: Stack( // (MỚI) Thêm Stack để hiển thị icon camera
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.lightRedAccent,
                  // (SỬA) Hiển thị ảnh nền
                  backgroundImage: auth.avatarUrl != null
                      ? NetworkImage(auth.avatarUrl!)
                      : null,
                  // (SỬA) Chỉ hiển thị chữ nếu không có ảnh
                  child: auth.avatarUrl != null
                      ? null
                      : Text(
                          auth.fullName?.isNotEmpty == true
                              ? auth.fullName![0].toUpperCase()
                              : '?',
                          style: textTheme.displayMedium
                              ?.copyWith(color: AppColors.primary),
                        ),
                ),
                // (MỚI) Icon camera
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300)
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primary,
                    size: 20,
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          Text(
            auth.fullName ?? '...',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tài khoản: ${auth.account ?? '...'}',
            style: textTheme.titleMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 30),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.primary),
              title: const Text('Ứng dụng PTIT Worker'),
              subtitle: const Text('Phiên bản 1.0 - Quản lý nhóm và tác vụ'),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Đăng Xuất',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => _handleLogout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}