import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../providers/invitation_provider.dart';
// (ĐÃ XÓA: import '../models/my_task_model.dart';)
import '../models/invitation_model.dart';
import '../core/app_colors.dart';
import 'group_detail_screen.dart';
import 'personal_tab.dart';
// (ĐÃ XÓA: import 'info_tab.dart';)
import 'my_tasks_tab.dart'; // (MỚI) Import file tab My Tasks

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  int _selectedIndex = 0; // Bắt đầu ở tab Nhóm

  final _groupNameCtrl = TextEditingController();
  final _groupDescCtrl = TextEditingController();

  // (CẬP NHẬT) 4 Trang
  static const List<Widget> _pages = <Widget>[
    _GroupListView(),
    MyTaskListView(), // Tab mới: Nhiệm vụ của tôi
    _InvitationListView(),
    PersonalTabView(), // Tab Cá nhân
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // (CẬP NHẬT) 4 Tiêu đề
  static const List<String> _appBarTitles = <String>[
    'Nhóm Của Tôi',
    'Nhiệm Vụ Của Tôi',
    'Lời Mời',
    'Thông Tin Cá Nhân',
  ];

  @override
  void dispose() {
    _groupNameCtrl.dispose();
    _groupDescCtrl.dispose();
    super.dispose();
  }

  void _showCreateGroupDialog() {
    _groupNameCtrl.clear();
    _groupDescCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo nhóm mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField( controller: _groupNameCtrl, decoration: const InputDecoration(labelText: 'Tên nhóm'), autofocus: true, ),
            const SizedBox(height: 15),
            TextField( controller: _groupDescCtrl, decoration: const InputDecoration(labelText: 'Mô tả'), ),
          ],
        ),
        actions: [
          TextButton( onPressed: () => Navigator.pop(ctx), child: const Text('Hủy'), ),
          ElevatedButton( onPressed: () => _handleCreateGroup(ctx), child: const Text('Tạo'), ),
        ],
      ),
    );
  }

  Future<void> _handleCreateGroup(BuildContext dialogContext) async {
    if (_groupNameCtrl.text.isEmpty) return;
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    try {
      await groupProvider.createGroup( _groupNameCtrl.text, _groupDescCtrl.text, );
      if (mounted) Navigator.pop(dialogContext);
    } catch (e) {
      if (mounted) { Navigator.pop(dialogContext); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}'))); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "AppBar giả" - Tiêu đề lơ lửng
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 10),
              child: Text(
                _appBarTitles[_selectedIndex],
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: _pages.elementAt(_selectedIndex),
              ),
            ),
          ],
        ),
      ),
      // Chỉ hiện nút FAB ở tab Nhóm (index 0)
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _showCreateGroupDialog,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        // (CẬP NHẬT) 4 items
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem( icon: Icon(Icons.group), label: 'Nhóm', ),
          BottomNavigationBarItem( icon: Icon(Icons.assignment_turned_in), label: 'Nhiệm vụ', ), // (MỚI)
          BottomNavigationBarItem( icon: Icon(Icons.mail), label: 'Lời Mời', ),
          BottomNavigationBarItem( icon: Icon(Icons.person), label: 'Cá nhân', ), // (Bỏ Info)
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Quan trọng để hiện đủ 4 items
      ),
    );
  }
}

// (_GroupListView giữ nguyên)
class _GroupListView extends StatefulWidget {
  const _GroupListView();
  @override State<_GroupListView> createState() => _GroupListViewState();
}
class _GroupListViewState extends State<_GroupListView> {
  bool _loading = true;
  @override void initState() { super.initState(); _loadGroups(); }
  Future<void> _loadGroups() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    try { await groupProvider.fetchGroups(); }
    catch (e) { if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi tải nhóm'))); } }
    if (mounted) { setState(() => _loading = false); }
  }
  @override Widget build(BuildContext context) {
    final groups = Provider.of<GroupProvider>(context, listen: true).groups;
    return AnimatedSwitcher( duration: const Duration(milliseconds: 300),
      child: _loading ? const Center(child: CircularProgressIndicator())
          : groups.isEmpty ? const Center(child: Text('Bạn chưa tham gia nhóm nào'))
          : ListView.builder( key: const ValueKey('group_list'), itemCount: groups.length, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemBuilder: (context, i) {
                final g = groups[i];
                return Card( color: AppColors.lightRedAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile( shape: Theme.of(context).cardTheme.shape, title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), subtitle: Text(g.description), trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => Navigator.push( context, MaterialPageRoute(builder: (_) => GroupDetailScreen(group: g))),
                  ),
                );
              }),
    );
  }
}

// (_InvitationListView giữ nguyên)
class _InvitationListView extends StatefulWidget {
  const _InvitationListView();
  @override State<_InvitationListView> createState() => _InvitationListViewState();
}
class _InvitationListViewState extends State<_InvitationListView> {
  bool _loading = true;
  @override void initState() { super.initState(); _loadInvitations(); }
  Future<void> _loadInvitations() async {
    final invProvider = Provider.of<InvitationProvider>(context, listen: false);
    try { await invProvider.fetchInvitations(); }
    catch (e) { if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi tải lời mời'))); } }
    if (mounted) { setState(() => _loading = false); }
  }
  Future<void> _handleReply(InvitationModel inv, String reply) async {
    final invProvider = Provider.of<InvitationProvider>(context, listen: false);
    try { await invProvider.replyToInvitation( inv.invitationId, inv.groupId, reply);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar( content: Text(reply == 'accepted' ? 'Đã chấp nhận lời mời' : 'Đã từ chối lời mời'))); }
      if (reply == 'accepted' && mounted) { Provider.of<GroupProvider>(context, listen: false).fetchGroups(); }
    } catch (e) { if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}'))); } }
  }
  @override Widget build(BuildContext context) {
    final invitations = Provider.of<InvitationProvider>(context).invitations;
    return AnimatedSwitcher( duration: const Duration(milliseconds: 300),
      child: _loading ? const Center(child: CircularProgressIndicator())
          : invitations.isEmpty ? const Center(child: Text('Bạn không có lời mời nào'))
          : ListView.builder( key: const ValueKey('invitation_list'), itemCount: invitations.length, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemBuilder: (context, i) {
                final inv = invitations[i];
                return Card( child: ListTile( shape: Theme.of(context).cardTheme.shape, title: Text(inv.title), subtitle: Text('ID lời mời: ${inv.invitationId}'),
                    trailing: Row( mainAxisSize: MainAxisSize.min, children: [
                        IconButton( icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _handleReply(inv, 'accepted'), ),
                        IconButton( icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _handleReply(inv, 'declined'), ),
                      ],
                    ),
                  ),
                );
              }),
    );
  }
}

// (ĐÃ XÓA: _MyTaskListView đã được chuyển ra file riêng)

