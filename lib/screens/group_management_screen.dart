// screens/group_management_screen.dart (FILE MỚI)

import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../models/group_model.dart';
import '../core/app_colors.dart';
import 'group_detail_screen.dart';
import 'edit_group_screen.dart';

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  // (Sao chép 2 hàm helper từ group_list_screen)
  final List<Color> _groupColors = [
    Colors.red, Colors.blue, Colors.green, Colors.orange,
    Colors.purple, Colors.teal, Colors.pink, Colors.indigo,
    Colors.amber, Colors.cyan, Colors.brown, Colors.lime,
  ];
  Color _getGroupColor(int groupId) {
    return _groupColors[groupId % _groupColors.length];
  }
  String _getFirstLetter(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }
  void _handleEditGroup(GroupModel group) {
    // (SỬA) Điều hướng đến màn hình Sửa
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditGroupScreen(group: group),
      ),
    );
  }
  // Hàm xử lý Xóa nhóm
  Future<void> _handleDeleteGroup(BuildContext context, GroupModel group) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa nhóm "${group.name}" không?'),
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

    try {
      context.loaderOverlay.show();
      await groupProvider.deleteGroup(group.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) context.loaderOverlay.hide();
    }
  }

  // Hàm xử lý Tạo nhóm
  void _showCreateGroupDialog() {
    final _groupNameCtrl = TextEditingController();
    final _groupDescCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) {
        final _formKey = GlobalKey<FormState>();
        return AlertDialog(
          title: const Text('Tạo nhóm mới'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _groupNameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên nhóm'),
                  autofocus: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return "Vui lòng nhập tên nhóm";
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _groupDescCtrl,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return "Vui lòng nhập miêu tả nhóm";
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() == false) return;
                Navigator.pop(ctx); // Đóng dialog
                final groupProvider = Provider.of<GroupProvider>(context, listen: false);
                try {
                  context.loaderOverlay.show();
                  await groupProvider.createGroup(_groupNameCtrl.text, _groupDescCtrl.text);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                } finally {
                  if (mounted) context.loaderOverlay.hide();
                }
              },
              child: const Text('Tạo'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final groups = groupProvider.groups; 
    final currentFilter = groupProvider.currentFilter;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lí nhóm'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Tạo nhóm mới',
      ),
      body: Column( 
        children: [
          // (Vẫn có bộ lọc ở đây)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Tất cả nhóm'),
                  selected: currentFilter == GroupFilter.all,
                  onSelected: (selected) {
                    if (selected) groupProvider.setFilter(GroupFilter.all);
                  },
                  selectedColor: AppColors.lightRedAccent,
                  labelStyle: TextStyle(
                    color: currentFilter == GroupFilter.all 
                        ? AppColors.primary 
                        : Colors.black54,
                    fontWeight: FontWeight.w600
                  ),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Tôi làm Leader'),
                  selected: currentFilter == GroupFilter.leader,
                  onSelected: (selected) {
                    if (selected) groupProvider.setFilter(GroupFilter.leader);
                  },
                  selectedColor: AppColors.lightRedAccent,
                  labelStyle: TextStyle(
                    color: currentFilter == GroupFilter.leader
                        ? AppColors.primary 
                        : Colors.black54,
                    fontWeight: FontWeight.w600
                  ),
                ),
                const SizedBox(width: 12),
                ChoiceChip( 
                  label: const Text('Tôi là Member'),
                  selected: currentFilter == GroupFilter.member,
                  onSelected: (selected) {
                    if (selected) groupProvider.setFilter(GroupFilter.member);
                  },
                  selectedColor: AppColors.lightRedAccent,
                  labelStyle: TextStyle(
                    color: currentFilter == GroupFilter.member
                        ? AppColors.primary 
                        : Colors.black54,
                    fontWeight: FontWeight.w600
                  ),
                ),
              ],
            ),
          ),

          // (Hiển thị danh sách đầy đủ)
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: groups.isEmpty
                  ? const Center(child: Text('Không tìm thấy nhóm nào.'))
                  : ListView.builder(
                      key: ValueKey(currentFilter),
                      itemCount: groups.length, // <-- Không giới hạn
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemBuilder: (context, i) {
                        final g = groups[i];
                        final groupColor = _getGroupColor(g.id);
                        final firstLetter = _getFirstLetter(g.name);
                        
                        final bool isLeader = g.myRole == 'leader';

                        return Card(
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: groupColor.withOpacity(0.2),
                              backgroundImage: g.avatarUrl != null
                                  ? NetworkImage(g.avatarUrl!)
                                  : null,
                              child: g.avatarUrl == null ? Text(
                                firstLetter,
                                style: TextStyle(
                                  color: groupColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ) : null,
                            ),
                            title: Text(
                              g.name,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              g.description,
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isLeader ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                  tooltip: 'Sửa nhóm',
                                  onPressed: () => _handleEditGroup(g),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: AppColors.primary),
                                  tooltip: 'Xóa nhóm',
                                  onPressed: () => _handleDeleteGroup(context, g),
                                ),
                              ],
                            ) : null, 
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GroupDetailScreen(group: g),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}