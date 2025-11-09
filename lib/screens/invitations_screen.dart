// screens/invitations_screen.dart (ĐÃ SỬA LỖI)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invitation_provider.dart';
import '../providers/group_provider.dart';
import '../models/invitation_model.dart';
import '../core/app_colors.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    try {
      await Provider.of<InvitationProvider>(context, listen: false)
          .fetchInvitations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải lời mời: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _handleReply(InvitationModel inv, String reply) async {
    final invProvider = Provider.of<InvitationProvider>(context, listen: false);
    try {
      await invProvider.replyToInvitation(inv.invitationId, inv.groupId, reply);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reply == 'accepted'
                  ? 'Đã chấp nhận lời mời'
                  : 'Đã từ chối lời mời',
            ),
          ),
        );
      }
      if (reply == 'accepted' && mounted) {
        // (SỬA LỖI) Chỉ cần gọi fetchGroups()
        // vì hàm này đã tải tất cả dữ liệu
        await Provider.of<GroupProvider>(context, listen: false).fetchGroups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitations = Provider.of<InvitationProvider>(context).invitations;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lời mời'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : invitations.isEmpty
                ? const Center(child: Text('Bạn không có lời mời nào'))
                : ListView.builder(
                    key: const ValueKey('invitation_list'),
                    itemCount: invitations.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemBuilder: (context, i) {
                      final inv = invitations[i];
                      return Card(
                        child: ListTile(
                          shape: Theme.of(context).cardTheme.shape,
                          title: Text(inv.title),
                          subtitle: Text('ID lời mời: ${inv.invitationId}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                onPressed: () => _handleReply(inv, 'accepted'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _handleReply(inv, 'declined'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}