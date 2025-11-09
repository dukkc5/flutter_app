// screens/edit_group_screen.dart (FILE MỚI)

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/group_model.dart';
import '../providers/group_provider.dart';
import '../core/app_colors.dart';
import '../widgets/custom_button.dart'; // (Giả sử bạn có file này)

class EditGroupScreen extends StatefulWidget {
  final GroupModel group;
  const EditGroupScreen({super.key, required this.group});

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  File? _selectedImage; // (MỚI) File ảnh đã chọn

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.group.name);
    _descCtrl = TextEditingController(text: widget.group.description);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // (MỚI) Hàm chọn ảnh
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // (MỚI) Hàm xử lý Lưu
  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() == false) {
      return;
    }
    
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    context.loaderOverlay.show();

    try {
      // 1. Upload ảnh (nếu có ảnh mới)
      if (_selectedImage != null) {
        await groupProvider.uploadGroupAvatar(widget.group.id, _selectedImage!);
      }
      
      // 2. Cập nhật Tên/Mô tả (nếu có thay đổi)
      if (_nameCtrl.text != widget.group.name || _descCtrl.text != widget.group.description) {
        await groupProvider.editGroup(widget.group.id, _nameCtrl.text, _descCtrl.text);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật nhóm thành công!')),
        );
        Navigator.pop(context); // Quay lại màn hình quản lý
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) context.loaderOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    // (MỚI) Lấy URL avatar hiện tại (có thể là null)
    final currentAvatarUrl = Provider.of<GroupProvider>(context)
        .groups
        .firstWhere((g) => g.id == widget.group.id)
        .avatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa thông tin nhóm'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // (MỚI) Vùng chọn Avatar
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.lightRedAccent,
                      // (MỚI) Hiển thị ảnh đã chọn, nếu không thì hiển thị ảnh cũ
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (currentAvatarUrl != null
                              ? NetworkImage(currentAvatarUrl)
                              : null) as ImageProvider?,
                      child: (_selectedImage == null && currentAvatarUrl == null)
                          ? Text(
                              widget.group.name.isNotEmpty ? widget.group.name[0] : '?',
                              style: const TextStyle(
                                fontSize: 40, 
                                color: AppColors.primary
                              ),
                            )
                          : null,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300)
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.camera_alt, color: AppColors.primary, size: 24),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Tên nhóm
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên nhóm'),
                validator: (value) {
                  if (value?.isEmpty ?? true) return "Tên nhóm không được rỗng";
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Mô tả
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 3,
                validator: (value) {
                  if (value?.isEmpty ?? true) return "Mô tả không được rỗng";
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Nút Lưu
              CustomButton(
                text: 'Lưu thay đổi', 
                onPressed: _handleSave
              ),
            ],
          ),
        ),
      ),
    );
  }
}