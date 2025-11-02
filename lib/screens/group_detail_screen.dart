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

class GroupDetailScreen extends StatefulWidget {
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
    _loadTasks();
    _loadMembers();
    _loadRole(); // Lấy role khi vào nhóm
  }

  Future<void> _loadRole() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    await groupProvider.fetchUserRoleInGroup(widget.group.id);
  }

  Future<void> _loadTasks() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    setState(() => _isLoadingTasks = true);
    try {
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

  // Dialog Sửa/Tạo Task Lớn
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

  void _showDeleteGroupDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa nhóm'),
        content: Text(
          'Bạn có chắc chắn muốn xóa nhóm "${widget.group.name}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleDeleteGroup();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận rời nhóm'),
        content: Text(
          'Bạn có chắc chắn muốn rời khỏi nhóm "${widget.group.name}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleLeaveGroup();
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

  Future<void> _handleSaveTask(
    BuildContext dialogContext, {
    TaskModel? existingTask,
  }) async {
    if (_titleCtrl.text.isEmpty || _selectedDeadline == null) return;
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    try {
      if (existingTask != null) {
        await taskProvider.updateTask(
          widget.group.id,
          existingTask.id,
          _titleCtrl.text,
          _descCtrl.text,
          _statusCtrl.text,
          _selectedDeadline!,
        );
      } else {
        await taskProvider.createTask(
          widget.group.id,
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
      await taskProvider.deleteTask(widget.group.id, taskId);
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
      await groupProvider.inviteMember(widget.group.id, _accountCtrl.text);
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
      await groupProvider.deleteMember(widget.group.id, member.account);
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
      await groupProvider.promoteMember(widget.group.id, member.userId);
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

  Future<void> _handleDeleteGroup() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    try {
      await groupProvider.deleteGroup(widget.group.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa nhóm "${widget.group.name}"')),
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

  Future<void> _handleLeaveGroup() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    try {
      await groupProvider.leaveGroup(widget.group.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã rời khỏi nhóm "${widget.group.name}"')),
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
    final List<MemberModel> members = Provider.of<GroupProvider>(
      context,
    ).members;
    final groupProvider = Provider.of<GroupProvider>(context); // Lắng nghe role
    final textTheme = Theme.of(context).textTheme;

    final isLeader = groupProvider.currentGroupRole == 'leader';
    final isLoadingRole = groupProvider.currentGroupRole == null;

    return Scaffold(
      floatingActionButton: isLeader && _tabController!.index == 0
          ? FloatingActionButton(
              onPressed: () => _showTaskDialog(),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : isLeader && _tabController!.index == 1
          ? FloatingActionButton(
              onPressed: _showAddMemberDialog,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person_add, color: Colors.white),
            )
          : null,

      body: SafeArea(
        child: Column(
          children: [
            // Thẻ thông tin nhóm
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: AppColors.primary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.group.name,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.group.description.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  widget.group.description,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.black54,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // CÁC NÚT HÀNH ĐỘNG
                      // Nút Rời nhóm (hiện cho mọi người)
                      IconButton(
                        icon: const Icon(
                          Icons.exit_to_app_outlined,
                          color: AppColors.grey,
                        ),
                        tooltip: 'Rời nhóm',
                        onPressed: _showLeaveGroupDialog,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.primary,
                        ),
                        tooltip: 'Tin nhắn nhóm',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChatScreen(groupId: widget.group.id , groupName: widget.group.name,),
                            ),
                          );
                        },
                      ),

                      // Nút Sửa/Xóa Nhóm (Chỉ Leader)
                      if (isLeader) ...[
                        IconButton(
                          icon: const Icon(
                            Icons.edit_note_outlined,
                            color: AppColors.grey,
                          ),
                          tooltip: 'Sửa nhóm',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Chức năng Sửa Nhóm (chưa làm)'),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_forever_outlined,
                            color: AppColors.primary,
                          ),
                          tooltip: 'Xóa nhóm',
                          onPressed: _showDeleteGroupDialog,
                        ),
                      ],
                      // Hiển thị loading nếu đang chờ role
                      if (isLoadingRole)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'hoàn thành':
        return Colors.green.shade50;
      case 'trễ hạn':
        return Colors.red.shade50;
      case 'đang làm':
        return Colors.blue.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  // Widget Task View (Kiểm soát quyền sửa/xóa task)
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
                        // Chỉ Leader mới xóa
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
                          child: const Icon(Icons.delete, color: Colors.white),
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
                            // Nút Sửa chỉ hiển thị cho Leader
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
                              // Cho phép mọi người nhấn vào để xem chi tiết giao việc
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TaskAssignmentsScreen(
                                    task: task,
                                    groupId: widget.group.id,
                                    isLeader: isLeader, // Truyền role
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

  // Widget Member View (Kiểm soát quyền quản lý thành viên)
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
                          title: Text(
                            member.fullName,
                            style: TextStyle(
                              fontWeight: member.role == 'leader'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text('Vai trò: ${member.role}'),
                          // Logic hiển thị nút 3 chấm: Chỉ Leader và không phải chính mình
                          trailing: (isLeader && !isCurrentUser)
                              ? IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () =>
                                      _showMemberOptionsDialog(member),
                                )
                              : null,
                          // Member KHÔNG được ấn vào (onTap = null)
                          // Trừ khi là Leader (để quản lý) HOẶC chính mình (để xem thông tin)
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
