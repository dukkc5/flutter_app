import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart'; // (MỚI) Import url_launcher

import '../models/task_model.dart';
import '../models/member_model.dart';
import '../models/assignment_model.dart';
import '../providers/task_provider.dart';
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';
import '../core/app_colors.dart';
import '../core/api_config.dart';
import 'package:intl/intl.dart';

class TaskAssignmentsScreen extends StatefulWidget {
  final TaskModel task;
  final int groupId;
  final bool isLeader;

  const TaskAssignmentsScreen({
    super.key,
    required this.task,
    required this.groupId,
    required this.isLeader,
  });

  @override
  State<TaskAssignmentsScreen> createState() => _TaskAssignmentsScreenState();
}

class _TaskAssignmentsScreenState extends State<TaskAssignmentsScreen> {
  bool _isLoadingAssignments = true;
  final _assignCommentCtrl = TextEditingController();
  final _assignStatusCtrl = TextEditingController();
  DateTime? _selectedAssignmentDeadline;

  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  final List<String> _assignmentStatuses = [
    'đang làm',
    'hoàn thành',
    'trễ hạn',
  ];

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _deleteFile(String fileUrl, int assignmentId) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    final url = Uri.parse('${ApiConfig.baseUrl}/files/$assignmentId');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa file thành công!')),
        );
        _loadAssignments(); // reload lại list
      } else {
        throw Exception('Server trả về lỗi: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xóa file: $e')));
      }
    }
  }

  Future<void> _loadAssignments() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    setState(() => _isLoadingAssignments = true);
    try {
      await taskProvider.fetchAssignmentsForTask(widget.task.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải giao việc: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAssignments = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          Provider.of<TaskProvider>(context, listen: false).clearAssignments();
        } catch (_) {}
      }
    });
    _assignCommentCtrl.dispose();
    _assignStatusCtrl.dispose();
    super.dispose();
  }

  // (MỚI) Hàm mở file
  Future<void> _launchFile(String fileUrl) async {
    // Nếu backend chỉ trả về tên file (vd: "abc.pdf" hoặc "/uploads/abc.pdf")
    // Ta cần chuẩn hóa lại để trỏ đúng endpoint /files/{file_name}

    String fileName = fileUrl.split('/').last; // Lấy phần tên file cuối cùng
    final fullUrl = Uri.parse('${ApiConfig.baseUrl}/files/$fileName');

    if (await canLaunchUrl(fullUrl)) {
      await launchUrl(
        fullUrl,
        mode: LaunchMode.externalApplication, // Mở bằng trình duyệt/app ngoài
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể mở file: $fullUrl')));
      }
    }
  }

  Future<void> _pickAndUploadFile(int assignmentId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    PlatformFile file = result.files.first;
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đang upload file: ${file.name}...')),
    );

    var url = Uri.parse('${ApiConfig.baseUrl}/files/uploads');
    var request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['assignment_id'] = assignmentId.toString();

    if (kIsWeb) {
      if (file.bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể đọc file trên Web')),
        );
        return;
      }
      request.files.add(
        http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name),
      );
    } else {
      if (file.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy đường dẫn file')),
        );
        return;
      }
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: file.name,
        ),
      );
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload thành công! Đang tải lại...')),
        );
        _loadAssignments();
      } else {
        throw Exception('Server trả về lỗi: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi upload file: $e')));
      }
    }
  }

  // Dialog để giao việc con mới
  void _showAssignMemberToTaskDialog() {
    final members = Provider.of<GroupProvider>(context, listen: false).members;
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    int? selectedUserId;
    _assignCommentCtrl.clear();
    _selectedAssignmentDeadline = null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text('Giao việc mới cho "${widget.task.title}"'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedUserId,
                      decoration: const InputDecoration(
                        labelText: 'Chọn thành viên',
                      ),
                      hint: const Text('Chọn người thực hiện'),
                      items: members.map((MemberModel member) {
                        return DropdownMenuItem<int>(
                          value: member.userId,
                          child: Text(member.fullName),
                        );
                      }).toList(),
                      onChanged: (int? newId) {
                        setDialogState(() => selectedUserId = newId);
                      },
                      validator: (value) =>
                          value == null ? 'Vui lòng chọn thành viên' : null,
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _assignCommentCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả công việc (comment)',
                      ),
                      maxLines: null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Chọn hạn hoàn thành:',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedAssignmentDeadline == null
                                ? 'Chưa chọn'
                                : _dateFormatter.format(
                                    _selectedAssignmentDeadline!,
                                  ),
                            style: TextStyle(fontSize: 14),
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
                              initialDate: _selectedAssignmentDeadline ?? now,
                              firstDate: now,
                              lastDate: now.add(const Duration(days: 365)),
                            );
                            if (pickedDate != null) {
                              setDialogState(() {
                                _selectedAssignmentDeadline = pickedDate;
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
                  onPressed:
                      (selectedUserId == null ||
                          _selectedAssignmentDeadline == null)
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          try {
                            await taskProvider.assignTaskNew(
                              widget.groupId,
                              widget.task.id,
                              selectedUserId!,
                              _assignCommentCtrl.text.trim(),
                              _selectedAssignmentDeadline!,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã giao việc thành công'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Lỗi giao việc: ${e.toString()}',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: const Text('Giao Việc'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog để Sửa Assignment
  void _showUpdateAssignmentDialog(AssignmentModel assignment) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    _assignCommentCtrl.text = assignment.comment ?? '';
    _selectedAssignmentDeadline = assignment.deadline;
    _assignStatusCtrl.text = assignment.status ?? 'pending';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text('Cập nhật giao việc cho ${assignment.fullName}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _assignCommentCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả công việc (comment)',
                      ),
                      maxLines: null,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Chọn hạn hoàn thành:',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedAssignmentDeadline == null
                                ? 'Chưa chọn'
                                : _dateFormatter.format(
                                    _selectedAssignmentDeadline!,
                                  ),
                            style: TextStyle(fontSize: 14),
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
                              initialDate: _selectedAssignmentDeadline ?? now,
                              firstDate: now,
                              lastDate: now.add(const Duration(days: 365)),
                            );
                            if (pickedDate != null) {
                              setDialogState(() {
                                _selectedAssignmentDeadline = pickedDate;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: _assignStatusCtrl.text,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                      ),
                      items: _assignmentStatuses.map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setDialogState(() {
                            _assignStatusCtrl.text = newValue;
                          });
                        }
                      },
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
                  onPressed: (_selectedAssignmentDeadline == null)
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          try {
                            await taskProvider.updateAssignment(
                              assignment.assignmentId,
                              widget.task.id,
                              _assignCommentCtrl.text.trim(),
                              _selectedAssignmentDeadline!,
                              _assignStatusCtrl.text,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã cập nhật giao việc'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Lỗi cập nhật: ${e.toString()}',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: const Text('Lưu Thay Đổi'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Hàm xử lý xóa assignment
  Future<void> _handleDeleteAssignment(int assignmentId) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    try {
      await taskProvider.deleteAssignment(assignmentId, widget.task.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã hủy giao việc')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi hủy giao việc: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignments = Provider.of<TaskProvider>(context).assignments;
    final textTheme = Theme.of(context).textTheme;
    final isLeader = widget.isLeader;

    return Scaffold(
      floatingActionButton: isLeader
          ? FloatingActionButton(
              onPressed: _showAssignMemberToTaskDialog,
              tooltip: 'Giao việc mới',
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_task, color: Colors.white),
            )
          : null,

      body: SafeArea(
        child: Column(
          children: [
            // Thẻ thông tin Task Lớn "lơ lửng"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 16.0,
                  ),
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
                              widget.task.title,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.task.description,
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Chip(
                                  label: Text(
                                    widget.task.status,
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  backgroundColor: _getTaskStatusColor(
                                    widget.task.status,
                                  ),
                                  padding: EdgeInsets.zero,
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Hạn: ${_dateFormatter.format(widget.task.deadline)}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Text(
                'Danh sách giao việc:',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isLoadingAssignments
                    ? const Center(child: CircularProgressIndicator())
                    : assignments.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 20.0,
                            horizontal: 16.0,
                          ),
                          child: Text(
                            'Chưa có ai được giao việc trong nhiệm vụ này. Nhấn nút (+) để giao việc.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        key: const ValueKey('assignments_list'),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: assignments.length,
                        itemBuilder: (context, index) {
                          final assignment = assignments[index];
                          final assignmentColor = _getAssignmentStatusColor(
                            assignment.status,
                          );

                          return Dismissible(
                            key: ValueKey(assignment.assignmentId),
                            direction: widget.isLeader
                                ? DismissDirection.endToStart
                                : DismissDirection.none,
                            onDismissed: (_) {
                              _handleDeleteAssignment(assignment.assignmentId);
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            child: Card(
                              color: assignmentColor,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                  horizontal: 16.0,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primary
                                          .withOpacity(0.1),
                                      child: Text(
                                        assignment.fullName.isNotEmpty
                                            ? assignment.fullName[0]
                                                  .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        assignment.fullName,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (assignment.comment != null &&
                                              assignment.comment!.isNotEmpty)
                                            Text(
                                              assignment.comment!,
                                              style: textTheme.bodyMedium,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          else
                                            Text(
                                              'Không có ghi chú',
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: Colors.grey,
                                                  ),
                                            ),
                                          if (assignment.deadline != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4.0,
                                              ),
                                              child: Text(
                                                'Hạn: ${_dateFormatter.format(assignment.deadline!)}',
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: Colors.black54,
                                                    ),
                                              ),
                                            ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4.0,
                                            ),
                                            child: Text(
                                              'Status: ${assignment.status ?? 'N/A'}',
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: Colors.black54,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),

                                          // (CẬP NHẬT) Hiển thị Chip nếu có file và làm nó click được
                                        ],
                                      ),
                                    ),

                                    // Nút Sửa (Chỉ Leader)
                                    if (widget.isLeader)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                        tooltip: 'Sửa giao việc',
                                        onPressed: () =>
                                            _showUpdateAssignmentDialog(
                                              assignment,
                                            ),
                                      ),

                                    // Nút Đính Kèm (Mọi người)
                                    // Nút Đính Kèm + Xóa file (nếu đã có)
                                    // Thay thế bằng đoạn này: attach lớn + dấu X nhỏ (nhưng logic onPressed đã đúng)
                                    Stack(
                                      alignment: Alignment.center,
                                      clipBehavior: Clip.none,
                                      children: [
                                        // Icon attach lớn — nếu đã có file: mở file, nếu chưa: pick & upload
                                        IconButton(
                                          icon: Icon(
                                            Icons.attach_file,
                                            size: 32,
                                            color:
                                                (assignment.attachmentUrl !=
                                                        null &&
                                                    assignment
                                                        .attachmentUrl!
                                                        .isNotEmpty)
                                                ? Colors.green
                                                : Colors.blueGrey,
                                          ),
                                          tooltip:
                                              (assignment.attachmentUrl !=
                                                      null &&
                                                  assignment
                                                      .attachmentUrl!
                                                      .isNotEmpty)
                                              ? 'Xem file đã đính kèm'
                                              : 'Đính kèm file',
                                          onPressed: () {
                                            if (assignment.attachmentUrl !=
                                                    null &&
                                                assignment
                                                    .attachmentUrl!
                                                    .isNotEmpty) {
                                              _launchFile(
                                                assignment.attachmentUrl!,
                                              ); // mở file hiện có
                                            } else {
                                              _pickAndUploadFile(
                                                assignment.assignmentId,
                                              ); // chọn & upload file mới
                                            }
                                          },
                                        ),

                                        // Dấu X nhỏ ở góc trên phải khi đã có file
                                        if (assignment.attachmentUrl != null &&
                                            assignment
                                                .attachmentUrl!
                                                .isNotEmpty)
                                          Positioned(
                                            top: 4,
                                            right: 6,
                                            child: InkWell(
                                              onTap: () async {
                                                // (Tuỳ chọn) hỏi xác nhận trước khi xóa
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text(
                                                      'Xác nhận',
                                                    ),
                                                    content: const Text(
                                                      'Bạn có chắc muốn xóa file này?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              ctx,
                                                              false,
                                                            ),
                                                        child: const Text(
                                                          'Hủy',
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              ctx,
                                                              true,
                                                            ),
                                                        child: const Text(
                                                          'Xóa',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  _deleteFile(
                                                    assignment.attachmentUrl!,
                                                    assignment.assignmentId,
                                                  );
                                                }
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
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
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // Hàm helper lấy màu status Task lớn
  Color _getTaskStatusColor(String status) {
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

  // Hàm helper lấy màu status Assignment
  Color _getAssignmentStatusColor(String? status) {
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
}
