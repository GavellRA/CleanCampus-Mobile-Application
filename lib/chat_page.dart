import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ChatPage extends StatefulWidget {
  final String userId;
  final String userName;

  const ChatPage({super.key, required this.userId, required this.userName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  // --- CONFIG ---
  final String _baseUrl = "http://192.168.0.179/aplikasisampah";
  final Color primaryColor = const Color(0xFF5DB8B4);
  final Color myBubbleColor = const Color(0xFF5DB8B4);
  final Color adminBubbleColor = Colors.white;

  List<Map<String, dynamic>> messages = [];
  bool _isSending = false;

  // --- DATA MENU BOT (PILIHAN KELUHAN) ---
  final List<Map<String, String>> botOptions = [
    {
      "label": "📦 Cara Lapor Sampah",
      "question": "Bagaimana cara melaporkan sampah?",
      "answer": "Untuk melapor: Klik ikon kamera di halaman utama, ambil foto sampah, isi deskripsi, lalu tekan 'Kirim Laporan'."
    },
    {
      "label": "💰 Poin Belum Masuk",
      "question": "Saya sudah lapor tapi poin belum masuk?",
      "answer": "Poin akan masuk setelah Admin memverifikasi laporan Anda. Proses ini memakan waktu maksimal 1x24 jam."
    },
    {
      "label": "🎁 Cara Tukar Hadiah",
      "question": "Bagaimana cara menukar poin?",
      "answer": "Masuk ke menu 'Tukar Poin' di Home, pilih item yang diinginkan, lalu klik 'Tukar'. Admin akan mengirim hadiah sesuai permintaan Anda."
    },
    {
      "label": "⚠️ Ajukan Keluhan",
      "question": "Saya ingin mengajukan keluhan.",
      "answer": "Baik, silakan ketik detail keluhan Anda di bawah ini. Admin kami akan segera merespons pesan Anda."
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // Auto refresh tiap 2 detik
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) => _fetchMessages());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- AMBIL PESAN ---
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
                  "isMe": msg['sender'] == 'user',
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

  // --- KIRIM PESAN (Bisa Manual / Bot) ---
  Future<void> _sendMessage({String? customText, String senderType = 'user'}) async {
    String text = customText ?? _controller.text.trim();
    if (text.isEmpty) return;

    if (senderType == 'user') {
      _controller.clear(); // Bersihkan input hanya jika user yang mengetik
    }

    setState(() => _isSending = true);

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/send_chat.php"),
        body: {
          "user_id": widget.userId,
          "message": text,
          "sender": senderType, // Bisa 'user' atau 'admin' (untuk Bot)
        },
      );

      if (response.statusCode == 200) {
        _fetchMessages();
        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal kirim: $e")));
    } finally {
      setState(() => _isSending = false);
    }
  }

  // --- LOGIKA BOT MENJAWAB ---
  void _handleBotOption(int index) async {
    String question = botOptions[index]['question']!;
    String answer = botOptions[index]['answer']!;

    // 1. Kirim Pertanyaan User ke Database
    await _sendMessage(customText: question, senderType: 'user');

    // 2. Efek "Bot sedang mengetik..." (Delay 1 detik)
    await Future.delayed(const Duration(seconds: 1));

    // 3. Kirim Jawaban Bot (Disimpan sebagai 'admin' di database agar muncul di kiri)
    await _sendMessage(customText: answer, senderType: 'admin');
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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.smart_toy_rounded, color: Color(0xFF5DB8B4)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("CS & Bantuan", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Bot Online", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // --- LIST PESAN ---
          Expanded(
            child: messages.isEmpty
                ? _buildWelcomeBot() // Tampilan awal jika chat kosong
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(15),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['isMe'];

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMe ? myBubbleColor : adminBubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(isMe ? 12 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 12),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(msg['message'], style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(msg['time'], style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // --- PILIHAN MENU BOT (Tombol Cepat) ---
          Container(
            height: 50,
            color: const Color(0xFFE5E5E5),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: botOptions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 5),
                  child: ActionChip(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: primaryColor.withOpacity(0.5)),
                    label: Text(botOptions[index]['label']!, style: TextStyle(color: primaryColor, fontSize: 12)),
                    onPressed: () => _handleBotOption(index),
                  ),
                );
              },
            ),
          ),

          // --- INPUT FIELD MANUAL ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(color: const Color(0xFFF5F5F0), borderRadius: BorderRadius.circular(25)),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: "Ketik pesan manual...", border: InputBorder.none),
                      minLines: 1, maxLines: 3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _isSending ? null : () => _sendMessage(),
                  child: CircleAvatar(
                    backgroundColor: primaryColor,
                    radius: 22,
                    child: _isSending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget Tampilan Awal Jika Chat Masih Kosong
  Widget _buildWelcomeBot() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent_rounded, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 15),
            const Text(
              "Halo! Ada yang bisa kami bantu?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            const Text(
              "Pilih topik di bawah atau ketik pesan manual.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}