import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TukarPoinPage extends StatefulWidget {
  final String userId;
  final VoidCallback onRefresh;

  const TukarPoinPage({
    super.key,
    required this.userId,
    required this.onRefresh
  });

  @override
  State<TukarPoinPage> createState() => _TukarPoinPageState();
}

class _TukarPoinPageState extends State<TukarPoinPage> {
  // Warna disamakan dengan Dashboard
  final Color primaryColor = const Color(0xFF5DB8B4);
  final Color secondaryColor = const Color(0xFF4A9894);
  final Color bgColor = const Color(0xFFF5F5F0);

  int _latestPoin = 0;
  bool _isLoading = true;

  final List<Map<String, dynamic>> hadiah = [
    {"nama": "Pulsa 5.000", "poin": 1000, "icon": Icons.phone_android_rounded},
    {"nama": "E-Wallet 10.000", "poin": 2000, "icon": Icons.account_balance_wallet_rounded},
    {"nama": "Voucher Listrik 20k", "poin": 4000, "icon": Icons.electric_bolt_rounded},
    {"nama": "Voucher Makan", "poin": 5000, "icon": Icons.restaurant_rounded},
    {"nama": "Tumbler Eksklusif", "poin": 7500, "icon": Icons.water_drop_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _fetchPointsFromDatabase();
  }

  Future<void> _fetchPointsFromDatabase() async {
    try {
      final String url =
          "http://192.168.0.179/aplikasisampah/get_profile.php?id=${widget.userId}&t=${DateTime.now().millisecondsSinceEpoch}";

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if ((data['status'] == 'success' || data['status'] == true) && mounted) {
          setState(() {
            _latestPoin = int.tryParse(data['points'].toString()) ?? 0;
            _isLoading = false;
          });
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('points', _latestPoin.toString());
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _kirimPermintaanTukar(String item, int harga) async {
    if (_latestPoin < harga) {
      _showError("Maaf, poin Anda tidak mencukupi.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // PERBAIKAN: Menggunakan IP 192.168.0.179 agar bisa connect dari HP/Emulator
      final response = await http.post(
        Uri.parse("http://192.168.0.179/aplikasisampah/tukar_poin.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "item_name": item,
          "points_spent": harga,
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      Navigator.pop(context);

      final data = jsonDecode(response.body);

      // PERBAIKAN: Logic cek status yang lebih aman (Success String ATAU True Boolean)
      if (data['status'] == 'success' || data['status'] == true) {
        widget.onRefresh();
        await _fetchPointsFromDatabase();
        _showSuccessDialog(data['message']);
      } else {
        _showError(data['message'] ?? "Gagal memproses penukaran.");
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showError("Terjadi kesalahan koneksi. Silakan coba lagi.");
    }
  }

  void _showSuccessDialog(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: primaryColor),
            const SizedBox(width: 10),
            const Text("Berhasil!", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. HEADER BACKGROUND (Mirip Dashboard)
          _buildHeaderBackground(),

          // 2. CONTENT
          SafeArea(
            child: Column(
              children: [
                // AppBar Custom transparan
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "Tukar Poin",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Tampilan Poin Besar
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Column(
                  children: [
                    const Text(
                      "Saldo Poin Anda",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Icon(Icons.stars_rounded, color: Color(0xFFFFC107), size: 28),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "$_latestPoin",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // LIST HADIAH
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: RefreshIndicator(
                      onRefresh: _fetchPointsFromDatabase,
                      color: primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 10, bottom: 30),
                        itemCount: hadiah.length,
                        itemBuilder: (context, index) {
                          final item = hadiah[index];
                          bool isCukup = _latestPoin >= item['poin'];
                          return _buildItemHadiah(item, isCukup);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget Header Gradient dengan Dekorasi Daun
  Widget _buildHeaderBackground() {
    return Stack(
      children: [
        ClipPath(
          clipper: SmoothHeaderClipper(), // Menggunakan clipper yang sama
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        // Dekorasi Daun (Sama seperti dashboard)
        Positioned(
          right: -20,
          top: -20,
          child: Opacity(
            opacity: 0.2,
            child: Icon(Icons.local_florist_rounded, color: Colors.white, size: 150),
          ),
        ),
        Positioned(
          left: 20,
          top: 80,
          child: Opacity(
            opacity: 0.1,
            child: Icon(Icons.eco_rounded, color: Colors.white, size: 80),
          ),
        ),
      ],
    );
  }

  Widget _buildItemHadiah(Map item, bool isCukup) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'] as IconData, color: primaryColor, size: 28),
              ),
              const SizedBox(width: 15),

              // Teks Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['nama'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          "${item['poin']} Poin",
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tombol Tukar
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCukup ? primaryColor : Colors.grey[300],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: isCukup
                    ? () => _kirimPermintaanTukar(item['nama'] as String, item['poin'] as int)
                    : null,
                child: Text(
                  isCukup ? "Tukar" : "Kurang",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tambahkan class Clipper ini di bagian bawah file
// (Sama persis dengan yang ada di dashboard.dart)
class SmoothHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);

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