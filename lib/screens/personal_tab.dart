import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/invitation_provider.dart';
import '../providers/task_provider.dart';
import '../core/app_colors.dart';
import '../screens/login_screen.dart';

class PersonalTabView extends StatelessWidget {
  const PersonalTabView({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final invProvider = Provider.of<InvitationProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.lightRedAccent,
            child: Text(
              auth.fullName?.isNotEmpty == true
                  ? auth.fullName![0].toUpperCase()
                  : '?',
              style: textTheme.displayMedium?.copyWith(color: AppColors.primary),
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
