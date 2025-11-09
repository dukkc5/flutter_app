import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart'; // (Vẫn giữ cho các hành động Tạo/Xóa)
import 'package:provider/provider.dart';
import 'package:pythonproject/providers/notification_provider.dart';
import 'package:pythonproject/screens/notifications_screen.dart';
import 'dart:math';

import '../providers/group_provider.dart';
import '../providers/invitation_provider.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';
import '../models/group_model.dart';
import '../models/invitation_model.dart';
import '../core/app_colors.dart';
import 'group_detail_screen.dart';
import 'personal_tab.dart';
import 'my_tasks_tab.dart';
import 'chat_screen.dart';
import 'invitations_screen.dart';
import 'package:intl/intl.dart';

import 'group_management_screen.dart';
import '../widgets/feature_button.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  static Future<void> loadInitialData(BuildContext context) async {
    // (Hàm này vẫn chạy ở SplashScreen, nên không cần sửa)
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final invProvider = Provider.of<InvitationProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final notiProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );

    await Future.wait([
      groupProvider.fetchGroups(),
      invProvider.fetchInvitations(),
      taskProvider.fetchMyTasks(),
      notiProvider.fetchNotifications()
    ]);
  }

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false; // (MỚI) State cho loading bar

  late final List<Widget> _pages;
  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      _GroupDashboardView(
        onNavigateToTab: _navigateToTab,
        onRefreshRequired: _refreshAllData, // (MỚI) Truyền hàm refresh
      ),
      _GroupChatListView(
        onRefreshRequired: _refreshAllData, // (MỚI) Truyền hàm refresh
      ),
      MyTaskListView(),
    ];
  }

  // (MỚI) Hàm refresh data cục bộ
  Future<void> _refreshAllData() async {
    setState(() => _isLoading = true); // Bật loading bar

    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final invProvider = Provider.of<InvitationProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final notiProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );

    try {
      await Future.wait([
        groupProvider.fetchGroups(),
        invProvider.fetchInvitations(),
        taskProvider.fetchMyTasks(),
        notiProvider.fetchNotifications(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi làm mới dữ liệu: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Tắt loading bar
      }
    }
  }

  // (MỚI) Callback để chuyển tab
  void _navigateToTab(int index) {
    _onItemTapped(index);
  }

  // (SỬA) Hàm Tapped
  void _onItemTapped(int index) async {
    // (SỬA) Thêm async
    if (_selectedIndex == index) return; // Không làm gì nếu nhấn tab cũ

    setState(() {
      _selectedIndex = index;
      _isLoading = true; // (MỚI) Bật loading bar
    });

    try {
      if (index == 2) {
        // Nhiệm vụ
        await Provider.of<TaskProvider>(context, listen: false).fetchMyTasks();
      } else if (index == 1) {
        // Tin nhắn
        await Provider.of<GroupProvider>(context, listen: false).fetchGroups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu tab: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // (MỚI) Tắt loading bar
      }
    }
  }

  static const List<String> _appBarTitles = <String>[
    'Trang chủ',
    'Tin nhắn',
    'Nhiệm Vụ Của Tôi',
  ];

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildBadgeIcon(IconData icon, int count) {
    // ... (Giữ nguyên)
    if (count == 0) return Icon(icon);
    return Stack(
      children: [
        Icon(icon),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
            constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
            child: Text(
              count > 9 ? '9+' : '$count',
              style: const TextStyle(color: Colors.white, fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final invProvider = Provider.of<InvitationProvider>(context);
    final notiProvider = Provider.of<NotificationProvider>(context);
    final invitationCount = invProvider.invitations.length;
    final notificationCount = notiProvider.notifications.length;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            // (SỬA) Dùng hàm refresh mới
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const Scaffold(body: PersonalTabView()),
                ),
              );
              await _refreshAllData(); // (SỬA)
            },
            child: CircleAvatar(
              backgroundColor: AppColors.lightRedAccent,
              backgroundImage: auth.avatarUrl != null
                  ? NetworkImage(auth.avatarUrl!)
                  : null,
              child: auth.avatarUrl == null
                  ? Text(
                      auth.fullName?.isNotEmpty == true
                          ? auth.fullName![0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        title: Text(
          _appBarTitles[_selectedIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _buildBadgeIcon(Icons.mail_outline, invitationCount),
            color: Colors.black54,
            tooltip: 'Lời mời',
            // (SỬA) Dùng hàm refresh mới
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InvitationsScreen()),
              );
              await _refreshAllData(); // (SỬA)
            },
          ),
          IconButton(
            icon: _buildBadgeIcon(Icons.notifications_none, notificationCount),
            color: Colors.black54,
            tooltip: 'Thông báo',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
              await _refreshAllData();
            },
          ),
        ],
      ),
      // (SỬA) Body
      body: Column(
        children: [
          // (MỚI) Linear Progress Bar
          Visibility(
            visible: _isLoading,
            child: const LinearProgressIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.lightRedAccent,
              minHeight: 3, // Làm nó mỏng
            ),
          ),
          Expanded(child: _pages.elementAt(_selectedIndex)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Nhóm'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Tin nhắn',
          ),
          BottomNavigationBarItem(
            icon: _buildBadgeIcon(
              Icons.assignment_turned_in,
              Provider.of<TaskProvider>(context).myTasks.length,
            ),
            label: 'Nhiệm vụ',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// ---------------------------------------------------------------------
// (SỬA) WIDGET TAB "TRANG CHỦ"
// ---------------------------------------------------------------------
class _GroupDashboardView extends StatefulWidget {
  final Function(int) onNavigateToTab;
  final Future<void> Function() onRefreshRequired; // (SỬA)
  const _GroupDashboardView({
    required this.onNavigateToTab,
    required this.onRefreshRequired,
  });

  @override
  State<_GroupDashboardView> createState() => _GroupDashboardViewState();
}

class _GroupDashboardViewState extends State<_GroupDashboardView> {
  // ... (các hàm helper _getGroupColor, _getFirstLetter giữ nguyên) ...
  final List<Color> _groupColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
    Colors.brown,
    Colors.lime,
  ];
  Color _getGroupColor(int groupId) {
    return _groupColors[groupId % _groupColors.length];
  }

  String _getFirstLetter(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final groups = groupProvider.groups;
    final currentFilter = groupProvider.currentFilter;
    final textTheme = Theme.of(context).textTheme;

    final int itemCount = min(groups.length, 5);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HÀNG LỌC
          SingleChildScrollView(
            // ... (code bộ lọc giữ nguyên) ...
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
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
                    fontWeight: FontWeight.w600,
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
                    fontWeight: FontWeight.w600,
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // DANH SÁCH GIỚI HẠN (5 NHÓM)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: groups.isEmpty
                ? const Center(
                    key: ValueKey('empty_groups'),
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Không tìm thấy nhóm nào.'),
                    ),
                  )
                : ListView.builder(
                    key: ValueKey(currentFilter),
                    itemCount: itemCount,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, i) {
                      final g = groups[i];
                      final groupColor = _getGroupColor(g.id);
                      final firstLetter = _getFirstLetter(g.name);

                      return Card(
                        elevation: 2,
                        child: InkWell(
                          // (SỬA) Thêm async/await
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GroupDetailScreen(group: g),
                              ),
                            );
                            await widget.onRefreshRequired(); // (SỬA)
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: groupColor.withOpacity(0.2),
                                  backgroundImage: g.avatarUrl != null
                                      ? NetworkImage(g.avatarUrl!)
                                      : null,
                                  child: g.avatarUrl == null
                                      ? Text(
                                          firstLetter,
                                          style: TextStyle(
                                            color: groupColor,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        g.name,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        g.description,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // NÚT QUẢN LÍ NHÓM
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                // (SỬA) Thêm async/await
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GroupManagementScreen(),
                    ),
                  );
                  await widget.onRefreshRequired(); // (SỬA)
                },
                child: Text('Quản lí nhóm (${groups.length} nhóm)'),
              ),
            ),
          ),

          const Divider(height: 32, indent: 16, endIndent: 16),

          // MỤC TÍNH NĂNG
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Tính năng & Lối tắt',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                FeatureButton(
                  text: 'Tin nhắn',
                  icon: Icons.chat_bubble_outline,
                  onTap: () => widget.onNavigateToTab(1), // Chuyển Tab 1
                ),
                FeatureButton(
                  text: 'Nhiệm vụ',
                  icon: Icons.assignment_turned_in_outlined,
                  onTap: () => widget.onNavigateToTab(2), // Chuyển Tab 2
                ),
                FeatureButton(
                  text: 'Lời mời',
                  icon: Icons.mail_outline,
                  onTap: () async {
                    // (SỬA)
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InvitationsScreen(),
                      ),
                    );
                    await widget.onRefreshRequired(); // (SỬA)
                  },
                ),
                FeatureButton(
                  text: 'Thông báo',
                  icon: Icons.notifications_none,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// WIDGET TAB "TIN NHẮN" (ZALO-STYLE)
// ---------------------------------------------------------------------
class _GroupChatListView extends StatefulWidget {
  // (SỬA)
  final Future<void> Function() onRefreshRequired;
  const _GroupChatListView({required this.onRefreshRequired});

  @override
  State<_GroupChatListView> createState() => _GroupChatListViewState();
}

class _GroupChatListViewState extends State<_GroupChatListView> {
  // (SỬA)
  // ... (Tất cả hàm helper: _getGroupColor, _getFirstLetter, _formatChatTimestamp GỮ NGUYÊN) ...
  Color _getGroupColor(int groupId) {
    final List<Color> _groupColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.brown,
      Colors.lime,
    ];
    return _groupColors[groupId % _groupColors.length];
  }

  String _getFirstLetter(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  String _formatChatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (date == today) {
      return DateFormat('HH:mm').format(timestamp.toLocal());
    } else if (date == yesterday) {
      return 'Hôm qua';
    } else {
      return DateFormat('dd/MM').format(timestamp.toLocal());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final groups = Provider.of<GroupProvider>(context).chatGroups;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: groups.isEmpty
          ? const Center(child: Text('Chưa có cuộc hội thoại nào.'))
          : ListView.builder(
              key: const ValueKey('chat_list'),
              itemCount: groups.length,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemBuilder: (context, i) {
                final g = groups[i];
                final groupColor = _getGroupColor(g.id);
                final firstLetter = _getFirstLetter(g.name);

                final bool hasMessage = g.lastMessageContent != null;
                final bool isMine =
                    hasMessage && g.lastMessageSender == auth.fullName;

                String subtitleText;
                if (!hasMessage) {
                  subtitleText = "Chưa có tin nhắn";
                } else if (isMine) {
                  subtitleText = "Bạn: ${g.lastMessageContent!}";
                } else {
                  final senderFirstName =
                      g.lastMessageSender?.split(' ').last ?? 'Ai đó';
                  subtitleText = "$senderFirstName: ${g.lastMessageContent!}";
                }

                return Card(
                  elevation: 0,
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: groupColor.withOpacity(0.2),
                      backgroundImage: g.avatarUrl != null
                          ? NetworkImage(g.avatarUrl!)
                          : null,
                      child: g.avatarUrl == null
                          ? Text(
                              firstLetter,
                              style: TextStyle(
                                color: groupColor,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      g.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      subtitleText,
                      style: textTheme.bodySmall?.copyWith(
                        color: hasMessage
                            ? Colors.black87
                            : Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      _formatChatTimestamp(g.lastMessageTimestamp),
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    // (SỬA) Thêm async/await
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChatScreen(groupId: g.id, groupName: g.name),
                        ),
                      );
                      await widget.onRefreshRequired(); // (SỬA)
                    },
                  ),
                );
              },
            ),
    );
  }
}
