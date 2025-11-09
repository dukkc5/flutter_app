import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

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

  WebSocketChannel? _channel;
  String? _token;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _token = Provider.of<AuthProvider>(context, listen: false).token;
    _fetchMessages();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _channel?.sink.close(status.goingAway);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- (CÁC HÀM HỖ TRỢ XỬ LÝ NGÀY) ---
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(date, now)) return 'Hôm nay';
    if (_isSameDay(date, yesterday)) return 'Hôm qua';
    return DateFormat('dd/MM/yyyy').format(date);
  }
  Widget _buildDateSeparator(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDateSeparator(date),
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
  // --- KẾT THÚC HÀM HỖ TRỢ ---

  // 🎯 HÀM NÀY ĐÃ CHUẨN: Dùng để cuộn khi có tin nhắn MỚI (có animation)
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _connectWebSocket() {
    if (_token == null) return;
    final wsUrl = Uri.parse(
        '${ApiConfig.baseUrl.replaceFirst('https', 'wss').replaceFirst('http', 'ws')}/chat/ws/${widget.groupId}/$_token');
    _channel = WebSocketChannel.connect(wsUrl);

    _channel!.stream.listen(
      (message) {
        try {
          final newMessage = jsonDecode(message) as Map<String, dynamic>;
          
          // Kiểm tra xem tin nhắn đã tồn tại chưa (tránh trường hợp http post và ws cùng chạy)
          // 🎯 LƯU Ý: Bạn nên có cơ chế chống trùng lặp tin nhắn.
          // Tạm thời tôi vẫn thêm
          
          _listKey.currentState?.insertItem(_messages.length);
          _messages.add({
            'id': newMessage['message_id'],
            'sender_name': newMessage['full_name'],
            'content': newMessage['content'],
            'timestamp': newMessage['timestamp'],
            'sender_avatar_url': newMessage['avatar_url'], // (MỚI)
          });
          _scrollToBottom(); // 🎯 GỌI Ở ĐÂY LÀ ĐÚNG (cho tin nhắn mới)
        } catch (e) {
          print("Lỗi giải mã tin nhắn WS: $e");
        }
      },
      onError: (error) { print('Lỗi WebSocket: $error'); },
      onDone: () { print('Đã ngắt kết nối WebSocket'); },
    );
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
                    'sender_avatar_url': m['avatar_url'], // (MỚI)
                  })
              .toList();
        });
        
        // 🎯 SỬA ĐỔI:
        // Chờ UI build xong rồi JUMP (nhảy) thẳng xuống dưới cùng.
        // Không dùng animation khi tải lịch sử.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
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
    _messageController.clear();

    // 🎯 XÓA BỎ: KHÔNG cuộn ở đây.
    // Hàm _connectWebSocket (listener) sẽ lo việc cuộn
    // khi máy chủ gửi tin nhắn (của chính mình) trở lại.
    // _scrollToBottom(); 

    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final res = await http.post(
        Uri.parse(
            '${ApiConfig.baseUrl}/chat/send?group_id=${widget.groupId}&content=$content'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        print('❌ Gửi tin nhắn thất bại: ${res.body}');
        _messageController.text = content; // Trả lại tin nhắn nếu gửi lỗi
      }
      // (Không cần làm gì, WebSocket sẽ lo)
    } catch (e) {
      print('⚠️ Lỗi mạng khi gửi tin nhắn: $e');
      _messageController.text = content;
    }
  }

  String _formatTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  // (SỬA LẠI HOÀN TOÀN) Widget tin nhắn
  Widget _buildMessageItem(
      BuildContext context, int index, Animation<double> animation) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final msg = _messages[index];
    final isMine = msg['sender_name'] == auth.fullName;
    
    // (MỚI) Lấy avatar
    final String? avatarUrl = msg['sender_avatar_url'];
    final String senderInitial = (msg['sender_name'] != null && msg['sender_name'].isNotEmpty)
            ? msg['sender_name'][0].toUpperCase()
            : '?';

    // (MỚI) Widget Avatar
    Widget avatarWidget = CircleAvatar(
      radius: 18,
      backgroundColor: Colors.redAccent.shade100,
      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
          ? NetworkImage(avatarUrl)
          : null,
      child: (avatarUrl != null && avatarUrl.isNotEmpty)
          ? null
          : Text(
              senderInitial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
    );

    // Widget bong bóng chat
    Widget messageBubble = Flexible(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMine ? Colors.redAccent.shade100 : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                color: isMine ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );

    // Ghép lại
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5), // Sửa: Trượt từ dưới lên
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOut),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMine) avatarWidget, // (SỬA)
              if (!isMine) const SizedBox(width: 8),
              messageBubble,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            // Header (Giữ nguyên)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.primary, size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
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
                  const SizedBox(width: 48),
                ],
              ),
            ),
            
            // Danh sách tin nhắn
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : _messages.isEmpty
                      ? const Center(
                          child: Text('Chưa có tin nhắn nào trong nhóm này.'),
                        )
                      : AnimatedList(
                          key: _listKey,
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          initialItemCount: _messages.length,
                          itemBuilder: (ctx, index, animation) {
                            
                            // (Logic hiển thị ngày)
                            final currentMessage = _messages[index];
                            final currentTimestamp = DateTime.parse(currentMessage['timestamp']).toLocal();

                            bool showDateSeparator = false;
                            if (index == 0) {
                              showDateSeparator = true;
                            } else {
                              final previousMessage = _messages[index - 1];
                              final previousTimestamp = DateTime.parse(previousMessage['timestamp']).toLocal();
                              if (!_isSameDay(currentTimestamp, previousTimestamp)) {
                                showDateSeparator = true;
                              }
                            }

                            final messageWidget = _buildMessageItem(ctx, index, animation);

                            return Column(
                              children: [
                                if (showDateSeparator)
                                  _buildDateSeparator(currentTimestamp),
                                messageWidget,
                              ],
                            );
                          },
                        ),
            ),

            // Thanh gửi tin (Giữ nguyên)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _messageController,
                    builder: (context, value, child) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: (value.text.isNotEmpty)
                            ? IconButton(
                                key: const ValueKey('send_button'),
                                icon: const Icon(Icons.send,
                                    color: AppColors.primary),
                                onPressed: _sendMessage,
                              )
                            : const SizedBox(
                                key: ValueKey('empty_box'),
                                width: 48,
                              ),
                      );
                    },
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