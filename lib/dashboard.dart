import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'laporkan_sampah.dart';
import 'riwayat.dart';
import 'profile.dart';
import 'tukar_poin.dart';
import 'panduan_page.dart';

class DashboardPage extends StatefulWidget {
  final String name;
  final String userId;
  const DashboardPage({super.key, required this.name, required this.userId});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  int _totalPoin = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final String url = "http://192.168.0.179/aplikasisampah/get_user_stats.php?user_id=${widget.userId}&t=${DateTime.now().millisecondsSinceEpoch}";
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _totalPoin = int.tryParse(data['points'].toString()) ?? 0;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) _fetchStats();
  }
  
  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildHomeScreen(),
      const PanduanPage(),
      LaporkanSampahPage(userId: widget.userId),
      RiwayatPage(userId: widget.userId),
      ProfilePage(userId: widget.userId),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: _pages),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildFancyBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeScreen() {
    return RefreshIndicator(
      onRefresh: _fetchStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildCustomHeader(),
            const SizedBox(height: 15),
            _buildMainContent(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background Header dengan gradient hijau
        ClipPath(
          clipper: SmoothHeaderClipper(),
          child: Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5DB8B4), Color(0xFF4A9894)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "CleanCampus",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Selamat Datang\ndi CleanCampus!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Dekorasi daun di pojok kanan
        Positioned(
          right: 10,
          top: 80,
          child: Opacity(
            opacity: 0.3,
            child: Transform.rotate(
              angle: 0.3,
              child: const Icon(Icons.local_florist_rounded, color: Colors.white, size: 60),
            ),
          ),
        ),
        Positioned(
          right: 40,
          top: 55,
          child: Opacity(
            opacity: 0.25,
            child: Transform.rotate(
              angle: -0.2,
              child: const Icon(Icons.nature_rounded, color: Colors.white, size: 45),
            ),
          ),
        ),

        // Kartu Poin (sesuai dengan desain referensi)
        Positioned(
          bottom: -30,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.stars_rounded, color: Color(0xFFFFC107), size: 30),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Poin Saya",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Text(
                      "$_totalPoin Poin",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TukarPoinPage(
                          userId: widget.userId,    // 1. Kirim ID User dari Dashboard
                          onRefresh: _fetchStats,   // 2. Kirim fungsi refresh Dashboard ke halaman sebelah
                    ),
                    ),
                    );
                    },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F5F0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        "Tukar Poin",
                        style: TextStyle(color: Color(0xFF5DB8B4), fontWeight: FontWeight.w600),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF5DB8B4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 25),
          const Text(
            "Selamat Datang di CleanCampus!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const Text(
            "Ayo Jadikan Kampus Bersih & Hijau!",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Ilustrasi / Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F5F4), Color(0xFFD4EBE9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  "Laporkan sampah yang kamu temukan di area kampus, kumpulkan poin, dan tukarkan poinmu dengan hadiah menarik!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4A9894),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 15),
                // Ilustrasi sederhana dengan icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildIllustrationIcon(Icons.person_rounded, "Mahasiswa"),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5DB8B4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 30),
                    ),
                    _buildIllustrationIcon(Icons.recycling_rounded, "Daur Ulang"),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Alur Penggunaan (sesuai desain referensi)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStepCard(Icons.camera_alt_outlined, "Laporkan\nSampah", const Color(0xFF5DB8B4)),
                    _buildArrow(),
                    _buildStepCard(Icons.stars_outlined, "Kumpulkan\nPoin", const Color(0xFFFFC107)),
                    _buildArrow(),
                    _buildStepCard(Icons.card_giftcard_outlined, "Tukar\nHadiah", const Color(0xFFFF7043)),
                  ],
                ),
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  "Ambil foto sampah, laporkan kepada kami,\nkumpulkan poin, dan tukarkan dengan\nhadiah menarik!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustrationIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF5DB8B4), size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF4A9894)),
        ),
      ],
    );
  }

  Widget _buildStepCard(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: Colors.grey, height: 1.2),
        ),
      ],
    );
  }

  Widget _buildArrow() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
    );
  }

  Widget _buildFancyBottomNav() {
    return Container(
      margin: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_rounded, "Home", 0),
          _navItem(Icons.menu_book_rounded, "Panduan", 1),
          _navItem(Icons.camera_alt_rounded, "Laporkan", 2),
          _navItem(Icons.history_rounded, "Riwayat", 3),
          _navItem(Icons.person_rounded, "Profil", 4),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF5DB8B4) : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? const Color(0xFF5DB8B4) : Colors.grey.shade400,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Clipper yang lebih smooth untuk header
class SmoothHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);

    // Kurva yang lebih smooth
    var firstControlPoint = Offset(size.width * 0.25, size.height - 20);
    var firstEndPoint = Offset(size.width * 0.5, size.height - 25);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width * 0.75, size.height - 30);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}