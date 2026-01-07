import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RiwayatPage extends StatefulWidget {
  final String userId;
  const RiwayatPage({super.key, required this.userId});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  late Future<List> _reportFuture;
  String _selectedStatus = 'semua';

  // Variabel Warna Konsisten
  final Color colorHijau = const Color(0xFF49A7A2);
  final Color colorHijauGelap = const Color(0xFF3B8A84);
  final Color colorCream = const Color(0xFFF5F5F0);

  // URL Base untuk memudahkan penggantian IP (Gunakan 10.0.2.2 untuk Emulator Android)
  final String baseUrl = "http://192.168.0.179/aplikasisampah";

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _reportFuture = fetchReports();
    });
  }

  Future<List> fetchReports() async {
    try {
      final String url = "$baseUrl/get_report.php?user_id=${widget.userId}&status=$_selectedStatus";
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server Error');
      }
    } catch (e) {
      throw Exception('Koneksi Bermasalah');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: colorCream,
      body: Stack(
        children: [
          // 1. HEADER WAVE
          ClipPath(
            clipper: BottomWaveClipper(),
            child: Container(height: screenHeight * 0.16, color: const Color(0xFF5AB1A9).withOpacity(0.4)),
          ),
          ClipPath(
            clipper: MiddleWaveClipper(),
            child: Container(height: screenHeight * 0.14, color: colorHijauGelap),
          ),
          ClipPath(
            clipper: TopWaveClipper(),
            child: Container(
              height: screenHeight * 0.11,
              color: colorHijau,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Row(children: [
                    const Icon(Icons.history_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                        "Riwayat Laporan",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ]),
                ),
              ),
            ),
          ),

          // 2. KONTEN UTAMA
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.13),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Pantau status laporan kebersihanmu di sini.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                ),

                _buildFilterBar(),

                const SizedBox(height: 10),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshData,
                    color: colorHijau,
                    child: FutureBuilder<List>(
                      future: _reportFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator(color: colorHijau));
                        } else if (snapshot.hasError) {
                          return _buildEmptyState("Gagal memuat data riwayat.");
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return _buildEmptyState("Tidak ada laporan status $_selectedStatus.");
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 5, left: 20, right: 20, bottom: 120),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            return _buildReportCard(snapshot.data![index]);
                          },
                        );
                      },
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

  Widget _buildFilterBar() {
    List<Map<String, String>> statuses = [
      {'key': 'semua', 'label': 'Semua'},
      {'key': 'pending', 'label': 'Diproses'},
      {'key': 'verified', 'label': 'Selesai'},
      {'key': 'rejected', 'label': 'Ditolak'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: statuses.map((status) {
          bool isSelected = _selectedStatus == status['key'];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedStatus = status['key']!);
              _refreshData();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? colorHijau : Colors.transparent,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                status['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black54,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReportCard(dynamic item) {
    String status = item['status'].toString().toLowerCase();
    Color badgeColor = status == 'verified' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
    String badgeText = status == 'verified' ? "Selesai" : (status == 'rejected' ? "Ditolak" : "Diproses");

    String rawImages = item['image_url']?.toString() ?? "";
    List<String> photos = rawImages.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    String thumbnail = photos.isNotEmpty ? photos[0] : "";

    return GestureDetector(
      onTap: () => _showDetailRiwayat(item, photos),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                "$baseUrl/$thumbnail",
                width: 65, height: 65, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 65, height: 65, color: Colors.grey[100], child: const Icon(Icons.image_not_supported, size: 20, color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      item['description'] ?? "Laporan Sampah",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D2D2D)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 4),
                  Text("Berat: ${item['weight']} Kg", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      if (status == 'verified')
                        Row(
                          children: [
                            const Icon(Icons.stars_rounded, size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                            const Text("+20 Poin", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIKA ZOOM DIPERBARUI (MENGIKUTI ADMIN PAGE) ---
  void _showDetailRiwayat(dynamic item, List<String> photos) {
    String status = item['status'].toString().toLowerCase();
    Color badgeColor = status == 'verified' ? Colors.green : (status == 'rejected' ? Colors.red : Colors.orange);
    String badgeText = status == 'verified' ? "SELESAI" : (status == 'rejected' ? "DITOLAK" : "DIPROSES");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9, // Lebar dialog proporsional
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AREA GAMBAR DENGAN INTERACTIVE VIEWER LANGSUNG
              Container(
                height: 250, // Tinggi disamakan dengan Admin agar lega
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.black, // Background hitam agar gambar menonjol
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: photos.isNotEmpty
                      ? PageView.builder(
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      // Ini kuncinya: InteractiveViewer langsung di sini
                      return InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.network(
                          "$baseUrl/${photos[index]}",
                          fit: BoxFit.contain, // Agar seluruh gambar terlihat
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 50
                          ),
                        ),
                      );
                    },
                  )
                      : const Center(
                      child: Icon(Icons.image_not_supported, color: Colors.white54, size: 50)
                  ),
                ),
              ),

              // AREA TEXT DETAIL
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Detail Laporan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D2D2D))),
                        _buildStatusBadge(badgeText, badgeColor),
                      ],
                    ),
                    const Divider(height: 25),
                    _detailRow(Icons.notes_rounded, "Deskripsi", item['description'] ?? "-"),
                    const SizedBox(height: 10),
                    _detailRow(Icons.scale_rounded, "Berat", "${item['weight']} Kg"),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: colorHijau,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Tutup", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colorHijau),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              Text(value, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 50, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(msg, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }
}

// --- CLIPPERS ---
class TopWaveClipper extends CustomClipper<Path> {
  @override Path getClip(Size size) {
    var path = Path(); path.lineTo(0, size.height - 25);
    path.quadraticBezierTo(size.width * 0.5, size.height, size.width, size.height - 25);
    path.lineTo(size.width, 0); path.close(); return path;
  }
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class MiddleWaveClipper extends CustomClipper<Path> {
  @override Path getClip(Size size) {
    var path = Path(); path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(size.width * 0.5, size.height + 15, size.width, size.height - 20);
    path.lineTo(size.width, 0); path.close(); return path;
  }
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BottomWaveClipper extends CustomClipper<Path> {
  @override Path getClip(Size size) {
    var path = Path(); path.lineTo(0, size.height - 10);
    path.quadraticBezierTo(size.width * 0.5, size.height + 30, size.width, size.height - 10);
    path.lineTo(size.width, 0); path.close(); return path;
  }
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}