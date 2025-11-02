import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/api_config.dart';
import '../core/app_colors.dart';
import '../providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final int groupId;
  final String groupName;

  const ChatScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/chat/history/${widget.groupId}'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _messages = data
              .map((m) => {
                    'id': m['message_id'],
                    'sender_name': m['full_name'],
                    'content': m['content'],
                    'timestamp': m['timestamp'],
                  })
              .toList();
        });
      } else {
        print('❌ Lỗi khi lấy tin nhắn: ${res.body}');
      }
    } catch (e) {
      print('⚠️ Lỗi mạng khi fetch tin nhắn: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final res = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/chat/send?group_id=${widget.groupId}&content=$content'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final msg = jsonDecode(res.body);
        setState(() {
          _messages.add({
            'sender_name': auth.fullName ?? 'Bạn',
            'content': content,
            'timestamp': msg['timestamp'],
          });
        });
        _messageController.clear();
      } else {
        print('❌ Gửi tin nhắn thất bại: ${res.body}');
      }
    } catch (e) {
      print('⚠️ Lỗi mạng khi gửi tin nhắn: $e');
    }
  }

String _formatTime(String timestamp) {
  try {
    final dt = DateTime.parse(timestamp).toLocal();
    return DateFormat('HH:mm').format(dt); // chỉ giờ:phút
  } catch (_) {
    return '';
  }
}


  Widget _buildAvatar(String name, bool isMine) {
    final firstLetter = (name.isNotEmpty ? name[0].toUpperCase() : '?');
    return CircleAvatar(
      radius: 18,
      backgroundColor:
          isMine ? AppColors.primary.withOpacity(0.8) : Colors.redAccent.shade100,
      child: Text(
        firstLetter,
        style: TextStyle(
          color: isMine ? Colors.white : AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER TÊN NHÓM =====
            // ===== HEADER TÊN NHÓM (CÓ NÚT BACK) =====
Padding(
  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // 🔙 Nút quay lại
      IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.primary, size: 26),
        onPressed: () => Navigator.pop(context),
      ),

      // 🧾 Tên nhóm ở giữa
      Expanded(
        child: Center(
          child: Text(
            widget.groupName,
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),

      // chừa khoảng trống bên phải để căn giữa thật sự
      const SizedBox(width: 48),
    ],
  ),
),

            // ===== DANH SÁCH TIN NHẮN =====
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : _messages.isEmpty
                      ? const Center(
                          child: Text('Chưa có tin nhắn nào trong nhóm này.'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (ctx, i) {
  final msg = _messages[i];
  final isMine = msg['sender_name'] == auth.fullName;
  final senderInitial =
      (msg['sender_name'] != null && msg['sender_name'].isNotEmpty)
          ? msg['sender_name'][0].toUpperCase()
          : '?';

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment:
          isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        // ✅ Chỉ hiển thị avatar khi KHÔNG phải tin nhắn của mình
        if (!isMine)
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.redAccent.shade100,
            child: Text(
              senderInitial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (!isMine) const SizedBox(width: 8),

        // 🔹 Bong bóng tin nhắn
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isMine
                  ? Colors.redAccent.shade100 // 🔴 đỏ nhạt hơn
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Text(
                    msg['sender_name'] ?? 'Ẩn danh',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                if (!isMine) const SizedBox(height: 4),
                Text(
                  msg['content'] ?? '',
                  style: TextStyle(
                    color: isMine ? Colors.white : Colors.black,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(msg['timestamp'] ?? ''),
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isMine ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
},

                        ),
            ),

            // ===== THANH GỬI TIN =====
            Container(
              color: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.send, color: AppColors.primary),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
