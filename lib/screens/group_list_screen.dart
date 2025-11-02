import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../providers/invitation_provider.dart';
import '../providers/task_provider.dart'; 
import '../models/invitation_model.dart';
import '../core/app_colors.dart';
import 'group_detail_screen.dart';
import 'personal_tab.dart';
import 'my_tasks_tab.dart'; 

class GroupListScreen extends StatefulWidget {
  // Thêm một trường để nhận biết nếu màn hình được tải qua Splash Screen (tùy chọn)
  // final bool dataLoaded;
  const GroupListScreen({super.key});

  // PHƯƠNG THỨC TĨNH GÓI GỌN LOGIC TẢI DỮ LIỆU CHUNG
  static Future<void> loadInitialData(BuildContext context) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final invProvider = Provider.of<InvitationProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false); 

    await Future.wait([
      groupProvider.fetchGroups(),
      invProvider.fetchInvitations(),
      taskProvider.fetchMyTasks(), // Lấy nhiệm vụ của tôi
    ]);
    // Nếu bạn muốn hiển thị lỗi ở đây, bạn sẽ phải wrap trong try-catch
  }

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  int _selectedIndex = 0; 
  final _groupNameCtrl = TextEditingController();
  final _groupDescCtrl = TextEditingController();

  static const List<Widget> _pages = <Widget>[
    _GroupListView(),
    MyTaskListView(), 
    _InvitationListView(),
    PersonalTabView(), 
  ];

  @override
  void initState() {
    super.initState();
    // Sau khi chuyển logic tải sang SplashScreen, chúng ta không gọi nó ở đây nữa.
    // Dữ liệu đã có sẵn trong Provider.
  }
  
  // XÓA HÀM _loadInitialData() vì đã chuyển thành static method trong class cha

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Vẫn gọi lại API khi chuyển tab để đảm bảo dữ liệu mới nhất được tải
    if (index == 1) {
      Provider.of<TaskProvider>(context, listen: false).fetchMyTasks();
    } else if (index == 2) {
      Provider.of<InvitationProvider>(context, listen: false).fetchInvitations();
    }
  }

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

  // Hàm tạo icon với huy hiệu (Badge) - Sử dụng chung cho Lời mời và Nhiệm vụ
  Widget _buildBadgeIcon(IconData icon, int count) {
    if (count == 0) {
      return Icon(icon);
    }
    
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
            constraints: const BoxConstraints(
              minWidth: 12,
              minHeight: 12,
            ),
            child: Text(
              count > 9 ? '9+' : '$count', 
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Lắng nghe số lượng lời mời
    final invProvider = Provider.of<InvitationProvider>(context);
    final invitationCount = invProvider.invitations.length;
    
    // Lắng nghe số lượng nhiệm vụ của tôi
    final taskProvider = Provider.of<TaskProvider>(context);
    final myTaskCount = taskProvider.myTasks.length; 

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
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _showCreateGroupDialog,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem( icon: Icon(Icons.group), label: 'Nhóm', ),
          
          // TAB NHIỆM VỤ (Với Badge)
          BottomNavigationBarItem( 
            icon: _buildBadgeIcon(Icons.assignment_turned_in, myTaskCount), 
            label: 'Nhiệm vụ', 
          ),
          
          // TAB LỜI MỜI (Với Badge)
          BottomNavigationBarItem( 
            icon: _buildBadgeIcon(Icons.mail, invitationCount), 
            label: 'Lời Mời', 
          ),
          
          const BottomNavigationBarItem( icon: Icon(Icons.person), label: 'Cá nhân', ),
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
// CÁC LIST VIEW (Giữ nguyên, nhưng có thể bỏ biến _loading nếu cần)
// ---------------------------------------------------------------------

// (_GroupListView)
class _GroupListView extends StatefulWidget {
  const _GroupListView();
  @override State<_GroupListView> createState() => _GroupListViewState();
}
class _GroupListViewState extends State<_GroupListView> {
  // Bỏ _loading = true vì dữ liệu đã được tải trước
  // Nếu vẫn muốn dùng, hãy đặt _loading = false ngay lập tức hoặc xóa nó
  // bool _loading = true; 
  @override void initState() { 
    super.initState(); 
    // Nếu dữ liệu đã tải xong ở Splash, ta có thể bỏ đoạn delay này
    // Future.delayed(const Duration(milliseconds: 500), () {
    //    if (mounted) setState(() => _loading = false);
    // });
  }

  @override Widget build(BuildContext context) {
    final groups = Provider.of<GroupProvider>(context, listen: true).groups;

    return AnimatedSwitcher( duration: const Duration(milliseconds: 300),
      // Thay vì dùng _loading, ta hiển thị luôn dữ liệu đã có trong Provider
      child: groups.isEmpty 
          ? const Center(child: Text('Bạn chưa tham gia nhóm nào'))
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

// (_InvitationListView)
class _InvitationListView extends StatefulWidget {
  const _InvitationListView();
  @override State<_InvitationListView> createState() => _InvitationListViewState();
}
class _InvitationListViewState extends State<_InvitationListView> {
  // Bỏ _loading = true
  // bool _loading = true;
  @override void initState() { 
    super.initState(); 
    // Bỏ đoạn delay
    // Future.delayed(const Duration(milliseconds: 500), () {
    //    if (mounted) setState(() => _loading = false);
    // });
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
      // Giả định dữ liệu đã tải, hiển thị luôn.
      child: invitations.isEmpty 
          ? const Center(child: Text('Bạn không có lời mời nào'))
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