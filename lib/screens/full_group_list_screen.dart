// screens/full_group_list_screen.dart (FILE MỚI)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../core/app_colors.dart';
import 'group_detail_screen.dart';

class FullGroupListScreen extends StatefulWidget {
  const FullGroupListScreen({super.key});

  @override
  State<FullGroupListScreen> createState() => _FullGroupListScreenState();
}

class _FullGroupListScreenState extends State<FullGroupListScreen> {
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

  @override
  Widget build(BuildContext context) {
    // (Màn hình này cũng lắng nghe provider)
    final groupProvider = Provider.of<GroupProvider>(context);
    final groups = groupProvider.groups; 
    final currentFilter = groupProvider.currentFilter;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tất cả nhóm'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
                        return Card(
                          elevation: 2,
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GroupDetailScreen(group: g),
                              ),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: groupColor.withOpacity(0.2),
                                    child: Text(
                                      firstLetter,
                                      style: TextStyle(
                                        color: groupColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                            color: Colors.grey.shade600
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
          ),
        ],
      ),
    );
  }
}