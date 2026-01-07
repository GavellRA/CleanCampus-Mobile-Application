import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart'; // Pastikan file login.dart ada
import 'admin_chat_room.dart'; // Pastikan file ini ada

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late Future<List> _reportFuture;
  late Future<List> _redemptionFuture;
  late Future<List> _chatClientsFuture;
  late Future<List> _logsFuture;

  late TabController _tabController;

  final Color colorHijau = const Color(0xFF49A7A2);
  // IP Address (Sesuaikan dengan laptop)
  final String baseUrl = "http://192.168.0.179/aplikasisampah";

  @override
  void initState() {
    super.initState();
    // Length 4: Laporan, Hadiah, Chat, Security
    _tabController = TabController(length: 4, vsync: this);
    _refreshAdminData();
  }

  Future<void> _refreshAdminData() async {
    setState(() {
      _reportFuture = fetchAllReports();
      _redemptionFuture = fetchAllRedemptions();
      _chatClientsFuture = fetchChatClients();
      _logsFuture = fetchLogs();
    });
  }

  // --- FUNGSI AMBIL DATA (API) ---
  Future<List> fetchAllReports() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_all_reports.php")).timeout(const Duration(seconds: 10));
      return response.statusCode == 200 ? json.decode(response.body) : [];
    } catch (e) { return []; }
  }

  Future<List> fetchAllRedemptions() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_all_redemptions.php")).timeout(const Duration(seconds: 10));
      return response.statusCode == 200 ? json.decode(response.body) : [];
    } catch (e) { return []; }
  }

  Future<List> fetchChatClients() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_active_chats.php")).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success' ? data['data'] : [];
      }
      return [];
    } catch (e) { return []; }
  }

  Future<List> fetchLogs() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_logs.php")).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success' ? data['data'] : [];
      }
      return [];
    } catch (e) { return []; }
  }

  // --- ACTIONS (Update Status) ---
  Future<void> _updateStatus(String id, String status) async {
    try {
      await http.post(Uri.parse("$baseUrl/update_status.php"), body: {"id": id, "status": status});
      _refreshAdminData();
    } catch (e) { debugPrint(e.toString()); }
  }

  Future<void> _completeRedemption(String id) async {
    try {
      await http.post(Uri.parse("$baseUrl/update_redemption.php"), body: {"id": id, "status": "completed"});
      _refreshAdminData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konfirmasi Transfer Berhasil!")));
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1E9),
      body: Column(
        children: [
          _buildAdminHeader(context),
          // TabBar Navigasi
          TabBar(
            controller: _tabController,
            labelColor: colorHijau,
            unselectedLabelColor: Colors.grey,
            indicatorColor: colorHijau,
            isScrollable: true,
            tabs: const [
              Tab(text: "Laporan"),
              Tab(text: "Hadiah"),
              Tab(text: "Live Chat"),
              Tab(text: "Security"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListTab(_reportFuture, true),
                _buildListTab(_redemptionFuture, false),
                _buildChatTab(),
                _buildLogTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET TAB SECURITY LOGS ---
  Widget _buildLogTab() {
    return RefreshIndicator(
      onRefresh: _refreshAdminData,
      color: Colors.redAccent,
      child: FutureBuilder<List>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState("Belum ada aktivitas keamanan");
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final log = snapshot.data![index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security, color: Colors.redAccent),
                  ),
                  title: Text(log['action'] ?? "Aktivitas", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text("User: ${log['user_name']} (ID: ${log['user_id']})", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      Text("IP: ${log['ip_address']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      Text("Waktu: ${log['created_at']}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- WIDGET TAB CHAT ---
  Widget _buildChatTab() {
    return RefreshIndicator(
      onRefresh: _refreshAdminData,
      color: colorHijau,
      child: FutureBuilder<List>(
        future: _chatClientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState("Belum ada pesan masuk");
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final user = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: colorHijau.withOpacity(0.2),
                    child: Icon(Icons.person, color: colorHijau),
                  ),
                  title: Text(user['name'] ?? "User ${user['user_id']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user['email'] ?? "No Email"),
                  trailing: const Icon(Icons.chat_bubble_outline, color: Colors.grey),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminChatRoom(
                          userId: user['user_id'].toString(),
                          userName: user['name'] ?? "User",
                        ),
                      ),
                    );
                    _refreshAdminData();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- WIDGET LIST TAB (Laporan & Hadiah) ---
  Widget _buildListTab(Future<List> future, bool isReport) {
    return RefreshIndicator(
      onRefresh: _refreshAdminData,
      color: colorHijau,
      child: FutureBuilder<List>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState("Belum ada data");
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var item = snapshot.data![index];
              return isReport ? _buildReportCard(item) : _buildRedemptionCard(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(dynamic item) {
    String status = item['status']?.toString().toLowerCase() ?? 'pending';
    List<String> images = item['image_url'].toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListTile(
        onTap: () => _showDetailDialog(item),
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: images.isNotEmpty
              ? Image.network("$baseUrl/${images[0]}", width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
              : const Icon(Icons.image, size: 50),
        ),
        title: Text(item['nama_user'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Status: $status", style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }

  Widget _buildRedemptionCard(dynamic item) {
    bool isPending = item['status'] == 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.wallet_giftcard, color: Colors.white)),
        title: Text(item['item_name'] ?? "Hadiah", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("User: ${item['user_name']}"),
        trailing: isPending
            ? ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () => _showRedemptionConfirm(item),
          child: const Text("Konfirmasi TF", style: TextStyle(color: Colors.white, fontSize: 10)),
        )
            : const Icon(Icons.check_circle, color: Colors.blue),
      ),
    );
  }

  // --- DETAIL DIALOG ---
  void _showDetailDialog(dynamic item) {
    double berat = double.tryParse(item['weight'].toString()) ?? 0.0;
    int potensiPoin = (berat * 1000).toInt();
    String status = item['status']?.toString().toLowerCase() ?? 'pending';
    List<String> listFoto = item['image_url'].toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    String deskripsi = item['description'] ?? "-";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 250,
                width: double.infinity,
                decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25))),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
                  child: listFoto.isNotEmpty
                      ? PageView.builder(
                    itemCount: listFoto.length,
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        child: Image.network("$baseUrl/${listFoto[index]}", fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white)),
                      );
                    },
                  )
                      : const Icon(Icons.image_not_supported, color: Colors.white54, size: 50),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['nama_user'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Divider(),
                    _buildInfoRow(Icons.scale, "Berat", "$berat Kg"),
                    _buildInfoRow(Icons.stars, "Potensi", "$potensiPoin Poin"),
                    _buildInfoRow(Icons.info, "Status", status.toUpperCase()),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.description, size: 18, color: colorHijau),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Deskripsi:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(deskripsi, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (status == 'pending')
                      Row(
                        children: [
                          Expanded(
                              child: OutlinedButton(
                                  onPressed: () { Navigator.pop(context); _updateStatus(item['id'].toString(), 'rejected'); },
                                  child: const Text("Tolak", style: TextStyle(color: Colors.red)))),
                          const SizedBox(width: 10),
                          Expanded(
                              child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: colorHijau),
                                  onPressed: () { Navigator.pop(context); _updateStatus(item['id'].toString(), 'verified'); },
                                  child: const Text("Verifikasi", style: TextStyle(color: Colors.white)))),
                        ],
                      )
                    else
                      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup"))),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminHeader(BuildContext context) {
    return ClipPath(
      clipper: AdminHeaderClipper(),
      child: Container(
        height: 160,
        width: double.infinity,
        color: colorHijau,
        padding: const EdgeInsets.only(top: 40, left: 25, right: 25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Admin Panel", style: TextStyle(color: Colors.white, fontSize: 16)),
              Text("Dashboard", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ]),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [Icon(icon, size: 18, color: colorHijau), const SizedBox(width: 10), Expanded(child: Text("$label: $value", overflow: TextOverflow.ellipsis))]),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'verified') return Colors.green;
    if (status == 'rejected') return Colors.red;
    return Colors.orange;
  }

  void _showRedemptionConfirm(dynamic item) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Konfirmasi"),
          content: Text("Sudah kirim hadiah ke ${item['user_name']}?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(onPressed: () { Navigator.pop(context); _completeRedemption(item['id'].toString()); }, child: const Text("Ya")),
          ],
        ));
  }

  Widget _buildEmptyState(String msg) => Center(child: Text(msg, style: const TextStyle(color: Colors.grey)));
} // <--- KURUNG KURAWAL PENUTUP YANG HILANG SUDAH ADA DI SINI

class AdminHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}