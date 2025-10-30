import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/my_task_model.dart';

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
                    // (CẬP NHẬT) Lấy màu theo status
                    final statusColor = getMyTaskStatusColor(task.status); 

                    return Card(
                      color: statusColor,
                      child: ListTile(
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
                        // (CẬP NHẬT) Thêm lại Chip Status
                        trailing: Chip(
                           label: Text(task.status ?? 'N/A', style: TextStyle(fontSize: 10)),
                           backgroundColor: statusColor, // Dùng màu nền nhạt
                           side: BorderSide(color: Colors.grey.shade300), // Thêm viền
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

