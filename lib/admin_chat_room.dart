import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class AdminChatRoom extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminChatRoom({super.key, required this.userId, required this.userName});

  @override
  State<AdminChatRoom> createState() => _AdminChatRoomState();
}

class _AdminChatRoomState extends State<AdminChatRoom> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  // URL API (Sesuaikan IP)
  final String _baseUrl = "http://192.168.0.179/aplikasisampah";

  // Warna Tema Admin (Bisa dibedakan sedikit)
  final Color primaryColor = const Color(0xFF5DB8B4);
  final Color adminBubbleColor = const Color(0xFF5DB8B4); // Admin (Kanan) pakai warna tema
  final Color userBubbleColor = Colors.white;             // User (Kiri) putih

  List<Map<String, dynamic>> messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) => _fetchMessages());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/get_chat.php?user_id=${widget.userId}"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          List<dynamic> serverMessages = data['data'];
          if (serverMessages.length != messages.length) {
            setState(() {
              messages = serverMessages.map((msg) {
                DateTime timestamp = DateTime.parse(msg['created_at']);
                String timeStr = "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";

                return {
                  "message": msg['message'],
                  // LOGIKA DIBALIK: Jika sender 'admin', maka isMe = true (Kanan)
                  "isMe": msg['sender'] == 'admin',
                  "time": timeStr,
                };
              }).toList();
            });
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _sendMessage() async {
    String text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/send_chat.php"),
        body: {
          "user_id": widget.userId, // Kirim ke ID user yang sedang dibuka
          "message": text,
          "sender": "admin", // PENTING: Pengirim adalah admin
        },
      );

      if (response.statusCode == 200) {
        _controller.clear();
        _fetchMessages();
        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal kirim: $e")));
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.userName, style: const TextStyle(fontSize: 16)),
            const Text("User Aplikasi", style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(15),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['isMe']; // true jika admin

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMe ? adminBubbleColor : userBubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(isMe ? 12 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 12),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: const Offset(0, 1))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(msg['message'], style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                        const SizedBox(height: 4),
                        Text(msg['time'], style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Balas pesan...",
                      filled: true,
                      fillColor: const Color(0xFFF5F5F0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: primaryColor,
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}