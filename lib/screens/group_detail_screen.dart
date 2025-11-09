// screens/group_detail_screen.dart (Full code - Đã hoàn trả)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pythonproject/screens/chat_screen.dart';
import '../models/group_model.dart';
import '../core/app_colors.dart';
import '../providers/task_provider.dart';
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';
import '../models/task_model.dart';
import '../models/member_model.dart';
import 'task_assignments_screen.dart';
import 'dart:async';

import 'group_info_screen.dart'; 
import 'edit_group_screen.dart'; 

enum GroupMenuAction { edit, leave, delete }

class GroupDetailScreen extends StatefulWidget {
  // (SỬA) Trả lại constructor cũ
  final GroupModel group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  bool _isLoadingTasks = true;
  bool _isLoadingMembers = true;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _statusCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _assignCommentCtrl = TextEditingController();

  DateTime? _selectedDeadline;
  final List<String> _taskStatuses = ['đang làm', 'hoàn thành', 'trễ hạn'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(() => setState(() {}));
    
    // (SỬA) Gọi hàm load data dùng widget.group.id
    _loadAllData();
  }
  
  Future<void> _loadAllData() async {
    _loadTasks();
    _loadMembers();
    _loadRole();
  }

  String _getFirstLetter(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  Future<void> _loadRole() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    // (SỬA) Dùng widget.group.id
    await groupProvider.fetchUserRoleInGroup(widget.group.id);
  }

  Future<void> _loadTasks() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    setState(() => _isLoadingTasks = true);
    try {
      // (SỬA) Dùng widget.group.id
      await taskProvider.fetchTasksForGroup(widget.group.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải nhiệm vụ: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingTasks = false);
      }
    }
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoadingMembers = true);
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    try {
      // (SỬA) Dùng widget.group.id
      await groupProvider.fetchMembersForGroup(widget.group.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải thành viên: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMembers = false);
      }
    }
  }

  @override
  void dispose() {
    try {
      Provider.of<TaskProvider>(context, listen: false).clearGroupTasks();
      Provider.of<GroupProvider>(context, listen: false).clearMembers();
      Provider.of<GroupProvider>(context, listen: false).clearGroupRole();
    } catch (_) {}

    _tabController?.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _statusCtrl.dispose();
    _accountCtrl.dispose();
    _assignCommentCtrl.dispose();
    super.dispose();
  }
  
  // (SỬA) Hàm xử lý khi chọn item từ Menu
  void _onMenuAction(GroupMenuAction action) {
    final groupData = widget.group; // (SỬA) Dùng widget.group
    switch(action) {
      case GroupMenuAction.leave:
        _showLeaveGroupDialog(groupData);
        break;
      case GroupMenuAction.edit:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditGroupScreen(group: groupData),
          ),
        );
        break;
      case GroupMenuAction.delete:
        _showDeleteGroupDialog(groupData);
        break;
    }
  }
  
  void _showTaskDialog({TaskModel? existingTask}) {
    bool isUpdating = existingTask != null;

    if (isUpdating) {
      _titleCtrl.text = existingTask.title;
      _descCtrl.text = existingTask.description;
      _statusCtrl.text = existingTask.status;
      _selectedDeadline = existingTask.deadline;
    } else {
      _titleCtrl.clear();
      _descCtrl.clear();
      _statusCtrl.text = 'đang làm';
      _selectedDeadline = null;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(isUpdating ? 'Sửa nhiệm vụ' : 'Tạo nhiệm vụ mới'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(labelText: 'Tiêu đề'),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: _statusCtrl.text,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                      ),
                      items: _taskStatuses.map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            _statusCtrl.text = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDeadline == null
                                ? 'Chưa chọn deadline'
                                : 'Deadline: ${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.calendar_month,
                            color: AppColors.primary,
                          ),
                          onPressed: () async {
                            final now = DateTime.now();
                            final pickedDate = await showDatePicker(
                              context: dialogContext,
                              initialDate: _selectedDeadline ?? now,
                              firstDate: now.subtract(const Duration(days: 30)),
                              lastDate: now.add(const Duration(days: 365)),
                            );
                            if (pickedDate != null) {
                              setDialogState(() {
                                _selectedDeadline = pickedDate;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: _selectedDeadline == null
                      ? null
                      : () => _handleSaveTask(ctx, existingTask: existingTask),
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Bottom Sheet chọn người gán task (nút này chỉ xuất hiện khi là Leader)

  void _showAddMemberDialog() {
    _accountCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mời thành viên'),
        content: TextField(
          controller: _accountCtrl,
          decoration: const InputDecoration(labelText: 'Tài khoản (account)'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => _handleInviteMember(ctx),
            child: const Text('Mời'),
          ),
        ],
      ),
    );
  }

  // Dialog quản lý thành viên (Chỉ Leader mới thấy)
  void _showMemberOptionsDialog(MemberModel member) {
    final isLeader =
        Provider.of<GroupProvider>(context, listen: false).currentGroupRole ==
        'leader';
    final isCurrentUser =
        Provider.of<AuthProvider>(context, listen: false).account ==
        member.account;

    if (!isLeader && !isCurrentUser) {
      // Nếu không phải Leader và không phải chính mình, chỉ hiện dialog thông tin
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          // (SỬA LỖI) Đặt tên context
          title: Text('Thông tin ${member.fullName}'),
          content: Text(
            'Vai trò: ${member.role}\nTài khoản: ${member.account}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      return;
    }

    // Nếu là Leader hoặc chính mình, hiện dialog quản lý
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(member.fullName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Chuyển thành Leader (Chỉ Leader mới thấy)
            if (isLeader && member.role != 'leader')
              ListTile(
                leading: const Icon(Icons.arrow_upward, color: Colors.blue),
                title: const Text('Chuyển thành Leader'),
                onTap: () {
                  Navigator.pop(ctx);
                  _handlePromoteMember(member);
                },
              ),
            // Xóa khỏi nhóm (Chỉ Leader mới thấy)
            if (isLeader && !isCurrentUser)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.primary),
                title: const Text('Xóa khỏi nhóm'),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleDeleteMember(member);
                },
              ),
            // Thông tin cơ bản (Nếu không có quyền quản lý, vẫn thấy)
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.grey),
              title: Text('Vai trò: ${member.role}'),
              subtitle: Text('Tài khoản: ${member.account}'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
  void _showDeleteGroupDialog(GroupModel group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa nhóm'),
        content: Text(
          'Bạn có chắc chắn muốn xóa nhóm "${group.name}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleDeleteGroup(group);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  void _showLeaveGroupDialog(GroupModel group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận rời nhóm'),
        content: Text(
          'Bạn có chắc chắn muốn rời khỏi nhóm "${group.name}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleLeaveGroup(group);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(
              'Rời Nhóm',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // (Các hàm logic handle... giữ nguyên)
  Future<void> _handleSaveTask(
    BuildContext dialogContext, {
    TaskModel? existingTask,
  }) async {
    if (_titleCtrl.text.isEmpty || _selectedDeadline == null) return;
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    try {
      if (existingTask != null) {
        await taskProvider.updateTask(
          widget.group.id, // (SỬA)
          existingTask.id,
          _titleCtrl.text,
          _descCtrl.text,
          _statusCtrl.text,
          _selectedDeadline!,
        );
      } else {
        await taskProvider.createTask(
          widget.group.id, // (SỬA)
          _titleCtrl.text,
          _descCtrl.text,
          _selectedDeadline!,
          _statusCtrl.text,
        );
      }
      if (mounted) Navigator.pop(dialogContext);
    } catch (e) {
      if (mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }
  Future<void> _handleDeleteTask(int taskId) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    try {
      await taskProvider.deleteTask(widget.group.id, taskId); // (SỬA)
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }
  Future<void> _handleInviteMember(BuildContext dialogContext) async {
    if (_accountCtrl.text.isEmpty) return;
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    try {
      await groupProvider.inviteMember(widget.group.id, _accountCtrl.text); // (SỬA)
      if (mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi lời mời thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }
  Future<void> _handleDeleteMember(MemberModel member) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    try {
      await groupProvider.deleteMember(widget.group.id, member.account); // (SỬA)
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã xóa ${member.fullName}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }
  Future<void> _handlePromoteMember(MemberModel member) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    try {
      await groupProvider.promoteMember(widget.group.id, member.userId); // (SỬA)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã chuyển ${member.fullName} thành Leader')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }
  Future<void> _handleDeleteGroup(GroupModel group) async { 
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    try {
      await groupProvider.deleteGroup(group.id); 
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa nhóm "${group.name}"')), 
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
      }
    }
  }
  Future<void> _handleLeaveGroup(GroupModel group) async { 
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    try {
      await groupProvider.leaveGroup(group.id); 
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã rời khỏi nhóm "${group.name}"')), 
        );
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
    final List<TaskModel> tasks = Provider.of<TaskProvider>(context).groupTasks;
    final List<MemberModel> members = Provider.of<GroupProvider>(context).members;
    final groupProvider = Provider.of<GroupProvider>(context); 
    final textTheme = Theme.of(context).textTheme;

    // (SỬA) Dùng group từ widget
    final group = widget.group;

    final isLeader = groupProvider.currentGroupRole == 'leader';
    final isLoadingRole = groupProvider.currentGroupRole == null;

    final String heroTag = 'group_hero_${group.id}'; 

    return Scaffold(
      floatingActionButton: isLeader && _tabController!.index == 0
          ? FloatingActionButton(
              heroTag: 'add_task_fab',
              onPressed: () => _showTaskDialog(),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : isLeader && _tabController!.index == 1
              ? FloatingActionButton(
                  heroTag: 'add_member_fab',
                  onPressed: _showAddMemberDialog,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.person_add, color: Colors.white),
                )
              : null,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Thẻ thông tin nhóm
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Hero(
                    tag: heroTag, 
                    child: Material(
                      type: MaterialType.transparency,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              opaque: false, 
                              barrierDismissible: true,
                              pageBuilder: (context, _, __) {
                                return GroupInfoScreen(
                                  group: group, // (SỬA)
                                  heroTag: heroTag,
                                );
                              },
                            ),
                          );
                        },
                        child: Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 8.0), 
                            child: ListTile(
                              leading: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: AppColors.primary,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              title: Text(
                                group.name, // (SỬA)
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: group.description.isNotEmpty // (SỬA)
                                  ? Text(
                                      group.description, // (SỬA)
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: Colors.black54,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              trailing: isLoadingRole
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    )
                                  : PopupMenuButton<GroupMenuAction>(
                                      icon: const Icon(Icons.more_vert,
                                          color: Colors.black54),
                                      onSelected: (action) => _onMenuAction(action), // (SỬA)
                                      itemBuilder: (BuildContext context) {
                                        final items = <
                                            PopupMenuEntry<GroupMenuAction>>[];
                                        if (isLeader) {
                                          items.add(
                                            const PopupMenuItem(
                                              value: GroupMenuAction.edit,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                      Icons.edit_note_outlined,
                                                      color: Colors.grey),
                                                  SizedBox(width: 8),
                                                  Text('Sửa nhóm'),
                                                ],
                                              ),
                                            ),
                                          );
                                          items.add(
                                            const PopupMenuItem(
                                              value: GroupMenuAction.delete,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                      Icons
                                                          .delete_forever_outlined,
                                                      color: AppColors.primary),
                                                  SizedBox(width: 8),
                                                  Text('Xóa nhóm'),
                                                ],
                                              ),
                                            ),
                                          );
                                        }
                                        items.add(
                                          const PopupMenuItem(
                                            value: GroupMenuAction.leave,
                                            child: Row(
                                              children: [
                                                Icon(
                                                    Icons.exit_to_app_outlined,
                                                    color: Colors.grey),
                                                SizedBox(width: 8),
                                                Text('Rời nhóm'),
                                              ],
                                            ),
                                          ),
                                        );
                                        return items;
                                      },
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // TabBar (2 Tabs)
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Nhiệm Vụ'),
                    Tab(text: 'Thành Viên'),
                  ],
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.grey,
                  indicatorColor: AppColors.primary,
                ),

                // TabBarView
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTaskView(tasks, isLeader),
                      _buildMemberView(members, isLeader),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Nút Chat ở góc dưới bên trái
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              heroTag: 'chat_fab', 
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      groupId: group.id, // (SỬA)
                      groupName: group.name, // (SỬA)
                    ),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.chat, color: Colors.white),
              tooltip: 'Tin nhắn nhóm',
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'hoàn thành': return Colors.green.shade50;
      case 'trễ hạn': return Colors.red.shade50;
      case 'đang làm': return Colors.blue.shade50;
      default: return Colors.grey.shade100;
    }
  }

  // Widget Task View
  Widget _buildTaskView(List<TaskModel> tasks, bool isLeader) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isLoadingTasks
                ? const Center(child: CircularProgressIndicator())
                : tasks.isEmpty
                    ? const Center(child: Text('Nhóm chưa có nhiệm vụ nào.'))
                    : ListView.builder(
                        key: const ValueKey('task_list'),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tasks.length,
                        itemBuilder: (ctx, i) {
                          final task = tasks[i];
                          final statusColor = _getStatusColor(task.status);

                          return Dismissible(
                            key: ValueKey(task.id),
                            direction: isLeader
                                ? DismissDirection.endToStart
                                : DismissDirection.none,
                            onDismissed: (_) {
                              _handleDeleteTask(task.id);
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: Card(
                              color: statusColor,
                              child: ListTile(
                                shape: Theme.of(context).cardTheme.shape,
                                title: Text(
                                  task.title,
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Trạng thái: ${task.status} | Deadline: ${task.deadline.day}/${task.deadline.month}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: isLeader
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: AppColors.grey,
                                        ),
                                        tooltip: 'Sửa thông tin nhiệm vụ',
                                        onPressed: () =>
                                            _showTaskDialog(existingTask: task),
                                      )
                                    : null,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TaskAssignmentsScreen(
                                        task: task,
                                        groupId: widget.group.id, // (SỬA)
                                        isLeader: isLeader, 
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // Widget Member View
  Widget _buildMemberView(List<MemberModel> members, bool isLeader) {
    final currentAccount = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).account;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isLoadingMembers
                ? const Center(child: CircularProgressIndicator())
                : members.isEmpty
                ? const Center(child: Text('Nhóm không có thành viên nào.'))
                : ListView.builder(
                    key: const ValueKey('member_list'),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    itemBuilder: (_, i) {
                      final member = members[i];
                      final isCurrentUser = member.account == currentAccount;

                      return Card(
                        child: ListTile(
                          shape: Theme.of(context).cardTheme.shape,
                          
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.lightRedAccent,
                            backgroundImage: member.avatarUrl != null
                                ? NetworkImage(member.avatarUrl!)
                                : null,
                            child: member.avatarUrl == null ? Text(
                              _getFirstLetter(member.fullName),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold
                              ),
                            ) : null,
                          ),
                          
                          title: Text(
                            member.fullName,
                            style: TextStyle(
                              fontWeight: member.role == 'leader'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text('Vai trò: ${member.role}'),
                          
                          trailing: (isLeader && !isCurrentUser)
                              ? IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () =>
                                      _showMemberOptionsDialog(member),
                                )
                              : null,
                          
                          onTap: isLeader || isCurrentUser
                              ? () => _showMemberOptionsDialog(member)
                              : null,
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}