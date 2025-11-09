// screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../core/app_colors.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 1. Tải danh sách
    Provider.of<NotificationProvider>(context, listen: false)
        .fetchNotifications()
        .whenComplete(() {
          if (mounted) setState(() => _isLoading = false);
        });
  }
  
  // Hàm xử lý khi nhấn Xóa tất cả
  Future<void> _handleDeleteAll() async {
     final provider = Provider.of<NotificationProvider>(context, listen: false);
     
     // Không cần hỏi nếu không có gì để xóa
     if (provider.notifications.isEmpty) return;
     
     final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc muốn xóa TẤT CẢ thông báo không?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true), 
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm != true) return;
      
      // Gọi provider để xóa
      await provider.deleteAllNotifications();
  }

  @override
  Widget build(BuildContext context) {
    // Dùng Provider.of
    final provider = Provider.of<NotificationProvider>(context);
    final notifications = provider.notifications;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Nút Xóa tất cả
          if (notifications.isNotEmpty && !_isLoading)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Xóa tất cả',
              onPressed: _handleDeleteAll,
            )
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isLoading
            ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
            : notifications.isEmpty
                ? const Center(key: ValueKey('empty'), child: Text('Bạn không có thông báo nào.'))
                : ListView.builder(
                    key: const ValueKey('list'),
                    itemCount: notifications.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, i) {
                      final notif = notifications[i];
                      return Card(
                        // (SỬA) Bỏ màu vì không còn 'isRead'
                        color: Colors.white,
                        child: ListTile(
                          leading: const Icon(
                            Icons.notifications,
                            color: AppColors.primary,
                          ),
                          title: Text(notif.message),
                          subtitle: Text(
                            DateFormat('HH:mm dd/MM/yyyy').format(notif.createdAt)
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}