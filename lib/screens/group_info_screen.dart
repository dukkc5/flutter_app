import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../core/app_colors.dart';

class GroupInfoScreen extends StatelessWidget {
  final GroupModel group;
  final String heroTag;

  const GroupInfoScreen({
    super.key,
    required this.group,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mediaQuery = MediaQuery.of(context);

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.6), // Nền mờ
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0), // Cách lề
              child: Hero(
                tag: heroTag,
                child: Material(
                  type: MaterialType.transparency,
                  child: GestureDetector(
                    onTap: () {}, // Chặn nhấn xuyên qua thẻ Card
                    child: Card(
                      elevation: 8,
                      // (SỬA LỖI) Bọc Column bằng một Container có giới hạn
                      child: Container(
                        constraints: BoxConstraints(
                          // Giới hạn chiều cao tối đa CỦA THẺ
                          maxHeight: mediaQuery.size.height * 0.8, // Tối đa 80% màn hình
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            // mainAxisSize: MainAxisSize.min, // (SỬA LỖI) Xóa dòng này
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hàng 1: Tiêu đề
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      group.name,
                                      style: textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: AppColors.primary),
                                    onPressed: () => Navigator.pop(context),
                                    tooltip: 'Đóng',
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              const SizedBox(height: 10),
                              
                              // (SỬA LỖI) Bọc bằng Flexible
                              Flexible(
                                child: SingleChildScrollView(
                                  child: Text(
                                    group.description.isNotEmpty
                                        ? group.description
                                        : 'Nhóm này không có mô tả.',
                                    style: textTheme.bodyLarge,
                                  ),
                                ),
                              ),
                              
                              // const SizedBox(height: 10), // (SỬA LỖI) Xóa dòng này
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}