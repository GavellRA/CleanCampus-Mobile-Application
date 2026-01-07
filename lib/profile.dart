import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'edit_profile.dart'; // Pastikan file ini ada
import 'chat_page.dart';    // [BARU] Pastikan file chat_page.dart sudah dibuat

class ProfilePage extends StatefulWidget {
  final String userId;
  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // --- WARNA TEMA ---
  final Color primaryColor = const Color(0xFF5DB8B4);
  final Color secondaryColor = const Color(0xFF4A9894);
  final Color bgColor = const Color(0xFFF5F5F0);

  bool _isLoading = true;
  String _userName = "...";
  String _userEmail = "...";
  String _userPhone = "";
  int _userPoints = 0;
  int _userReports = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserStats();
  }

  Future<void> _fetchUserStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Pastikan IP Address sesuai dengan laptop kamu
      final response = await http.get(
        Uri.parse("http://192.168.0.179/aplikasisampah/get_user_stats.php?user_id=${widget.userId}&t=${DateTime.now().millisecondsSinceEpoch}"),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _userName = data['name'] ?? "User";
            _userEmail = data['email'] ?? "-";
            _userPhone = data['phone'] ?? "";
            _userPoints = int.tryParse(data['points'].toString()) ?? 0;
            _userReports = int.tryParse(data['total_laporan'].toString()) ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile stats: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Konfirmasi"),
          ],
        ),
        content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
            child: const Text("Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: _fetchUserStats,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 60),

              // Nama User (Judul Besar)
              Text(
                _userName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D)
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                  "Pahlawan Lingkungan",
                  style: TextStyle(color: Colors.grey, fontSize: 14)
              ),

              const SizedBox(height: 30),

              // Kartu Poin & Laporan
              _buildAchievementCard(),

              const SizedBox(height: 25),

              // Kartu Informasi Pribadi (Email & HP)
              _buildPersonalInfoSection(),

              const SizedBox(height: 25),

              // Menu Navigasi
              _buildMenuSection(context),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET INFO PRIBADI ---
  Widget _buildPersonalInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 10, bottom: 10),
            child: Text("Informasi Pribadi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5)
                )
              ],
            ),
            child: Column(
              children: [
                _buildInfoDetailRow(Icons.email_outlined, "Email", _userEmail),
                const Divider(height: 1, indent: 60, endIndent: 20),
                _buildInfoDetailRow(
                    Icons.phone_iphone_rounded,
                    "No. Telepon",
                    _userPhone.isEmpty ? "Belum diatur" : _userPhone
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String avatarName = _userName.replaceAll(' ', '+');

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: SmoothHeaderClipper(),
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 30),
                  child: Text(
                    "Profil Pengguna",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Hiasan
        Positioned(
          right: -20, top: -20,
          child: Opacity(opacity: 0.2, child: Icon(Icons.local_florist_rounded, color: Colors.white, size: 150)),
        ),
        Positioned(
          left: 30, top: 80,
          child: Opacity(opacity: 0.15, child: Icon(Icons.eco_rounded, color: Colors.white, size: 60)),
        ),
        // Avatar
        Positioned(
          bottom: -50,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: primaryColor.withOpacity(0.2),
              backgroundImage: NetworkImage(
                  'https://ui-avatars.com/api/?name=$avatarName&background=5DB8B4&color=fff&size=256'
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _infoItem("Total Poin", _userPoints.toString(), Icons.stars_rounded, Colors.orange),
          const SizedBox(width: 15),
          _infoItem("Laporan Selesai", _userReports.toString(), Icons.check_circle_rounded, primaryColor),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 12),
            _isLoading
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor))
                : Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D))),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // --- BAGIAN MENU (DIPERBARUI UNTUK CHAT) ---
  Widget _buildMenuSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 10, bottom: 10),
            child: Text("Pengaturan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                _buildMenuTile(
                  Icons.edit_note_rounded,
                  "Edit Profil",
                  isFirst: true,
                  onTap: () async {
                    final bool? result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePage(
                          userId: widget.userId,
                          currentName: _userName,
                          currentEmail: _userEmail,
                          currentPhone: _userPhone,
                        ),
                      ),
                    );
                    if (result == true) {
                      _fetchUserStats();
                    }
                  },
                ),

                const Divider(height: 1, indent: 60),

                // [BARU] Menu ke Chat Page
                _buildMenuTile(
                    Icons.support_agent_rounded,
                    "Chat Admin / CS",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            userId: widget.userId,
                            userName: _userName,
                          ),
                        ),
                      );
                    }
                ),

                const Divider(height: 1, indent: 60),

                _buildMenuTile(
                  Icons.logout_rounded,
                  "Keluar Akun",
                  isLast: true,
                  color: Colors.redAccent,
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, {bool isFirst = false, bool isLast = false, Color? color, VoidCallback? onTap}) {
    Color itemColor = color ?? const Color(0xFF2D2D2D);
    Color iconBg = color?.withOpacity(0.1) ?? primaryColor.withOpacity(0.1);
    Color iconTint = color ?? primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.vertical(top: Radius.circular(isFirst ? 25 : 0), bottom: Radius.circular(isLast ? 25 : 0)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconTint, size: 22),
              ),
              const SizedBox(width: 15),
              Expanded(child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: itemColor))),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}

class SmoothHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    var firstControlPoint = Offset(size.width * 0.25, size.height - 20);
    var firstEndPoint = Offset(size.width * 0.5, size.height - 25);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);
    var secondControlPoint = Offset(size.width * 0.75, size.height - 30);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}