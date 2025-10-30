import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class InfoTabView extends StatelessWidget {
  const InfoTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            context,
            title: 'Thông báo Quan trọng',
            content:
                'Hệ thống đang được bảo trì từ 12:00 AM đến 1:00 AM hàng ngày để cải thiện hiệu suất. Vui lòng lưu lại công việc.',
            icon: Icons.campaign,
            color: Colors.orange,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(context, 'Hướng dẫn Sử dụng Cơ bản'),
          _buildGuideStep(
            context,
            1,
            'Tạo Nhóm',
            'Nhấn nút "+" ở góc dưới bên phải màn hình Nhóm Của Tôi để tạo nhóm và mời thành viên bằng tài khoản của họ.',
          ),
          _buildGuideStep(
            context,
            2,
            'Quản lý Nhiệm Vụ',
            'Vào chi tiết nhóm, nhấn nút "+" để tạo Task. Vuốt sang trái để xóa hoặc nhấn nút Edit để sửa trạng thái/deadline.',
          ),
          _buildGuideStep(
            context,
            3,
            'Trả lời Lời Mời',
            'Chuyển sang tab "Lời Mời" để chấp nhận hoặc từ chối lời mời tham gia nhóm.',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context,
      {required String title,
      required String content,
      required IconData icon,
      required Color color}) {
    return Card(
      elevation: 4,
      color: color.withOpacity(0.1),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(content),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildGuideStep(BuildContext context, int step, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text('$step', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(content, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
