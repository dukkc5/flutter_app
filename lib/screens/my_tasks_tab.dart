import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/my_task_model.dart';
import '../screens/group_detail_screen.dart'; 
import '../providers/group_provider.dart';
import '../models/group_model.dart'; 

// Hàm hỗ trợ (Giả định được định nghĩa/import)
Color getMyTaskStatusColor(String? status) {
  switch (status) {
    case 'hoàn thành': return Colors.green.shade50;
    case 'trễ hạn': return Colors.red.shade50;
    case 'đang làm': return Colors.blue.shade50;
    case 'pending': return Colors.yellow.shade50;
    default: return Colors.grey.shade100;
  }
}

String formatMyTaskDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

class MyTaskListView extends StatefulWidget {
  const MyTaskListView({super.key});

  @override
  State<MyTaskListView> createState() => _MyTaskListViewState();
}

class _MyTaskListViewState extends State<MyTaskListView> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMyTasks();
  }

  Future<void> _loadMyTasks() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      try {
        await taskProvider.fetchMyTasks();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Lỗi tải nhiệm vụ: ${e.toString()}')));
        }
      }
      if (mounted) {
        setState(() => _loading = false);
      }
    });
  }

  // HÀM XỬ LÝ KHI NHẤN VÀO NHIỆM VỤ: Điều hướng đến trang chi tiết nhóm (Tìm kiếm bằng groupId)
  void _navigateToGroupDetail(BuildContext context, MyTaskModel myTask) {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    
    final GroupModel group;
    try {
      // TÌM KIẾM NHÓM DỰA TRÊN GROUP ID (Cách chính xác và an toàn)
      group = groupProvider.groups.firstWhere(
        (g) => g.id == myTask.groupId, 
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Không tìm thấy nhóm tương ứng. Hãy đảm bảo nhóm đã được tải.')),
      );
      return;
    }
    
    // Chuyển đến trang chi tiết nhóm
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupDetailScreen(group: group),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final myTasks = Provider.of<TaskProvider>(context).myTasks;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : myTasks.isEmpty
              ? const Center(child: Text('Bạn chưa được giao nhiệm vụ nào.'))
              : ListView.builder(
                  key: const ValueKey('my_task_list'),
                  itemCount: myTasks.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemBuilder: (context, i) {
                    final task = myTasks[i];
                    final statusColor = getMyTaskStatusColor(task.status); 

                    return Card(
                      color: statusColor,
                      child: ListTile(
                        // GỌI HÀM ĐIỀU HƯỚNG KHI NHẤN
                        onTap: () => _navigateToGroupDetail(context, task),
                        shape: Theme.of(context).cardTheme.shape,
                        title: Text(task.taskTitle, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nhóm: ${task.groupName}', style: textTheme.bodySmall),
                            if (task.comment != null && task.comment!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Ghi chú: ${task.comment!}', 
                                  style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Hạn: ${formatMyTaskDate(task.deadline)}', 
                                  style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                                ),
                              ),
                          ],
                        ),
                        trailing: Chip(
                            label: Text(task.status ?? 'N/A', style: TextStyle(fontSize: 10)),
                            backgroundColor: statusColor, 
                            side: BorderSide(color: Colors.grey.shade300), 
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                        ),
                      ),
                    );
                  }),
    );
  }
}