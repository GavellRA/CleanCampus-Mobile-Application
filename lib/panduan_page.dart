import 'package:flutter/material.dart';

class PanduanPage extends StatelessWidget {
  const PanduanPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mendapatkan tinggi layar untuk proporsi header
    final screenHeight = MediaQuery.of(context).size.height;

    // Warna yang sama dengan Laporkan Sampah
    final Color colorHijau = const Color(0xFF49A7A2);
    final Color colorHijauGelap = const Color(0xFF3B8A84);
    final Color bgColor = const Color(0xFFF5F5F0); // Background abu muda

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. HEADER WAVE (Disamakan dengan Laporkan Sampah)
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
                    const Icon(Icons.eco, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    const Text("Panduan Aplikasi", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ),
          ),

          // 2. KONTEN (Menggunakan SingleScrollView biasa)
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Jarak dari atas diturunkan agar Konten berada di bawah gelombang
                  // Disamakan proporsinya dengan halaman lain
                  SizedBox(height: screenHeight * 0.13),

                  // Header Card (Cara Menggunakan)
                  _buildHeaderCard(),
                  const SizedBox(height: 30),

                  // Title Langkah-langkah
                  const Text(
                    'Langkah-langkah penggunaan',
                    style: TextStyle(
                      fontSize: 16, // Ukuran font disesuaikan agar rapi
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Step 1
                  _buildStepCard(
                    number: '1',
                    title: 'Laporkan Sampah',
                    description: 'Ambil foto sampah yang kamu temukan di area kampus dan kirimkan lewat aplikasi.',
                    icon: Icons.camera_alt_rounded,
                    color: colorHijau,
                    illustration: Icons.photo_camera_rounded,
                  ),

                  const SizedBox(height: 15),

                  // Step 2
                  _buildStepCard(
                    number: '2',
                    title: 'Kumpulkan Poin',
                    description: 'Setiap laporan yang kamu kirim dan sudah diterima oleh admin, kamu akan mendapatkan poin.',
                    icon: Icons.stars_rounded,
                    color: const Color(0xFFFFC107),
                    illustration: Icons.monetization_on_rounded,
                  ),

                  const SizedBox(height: 15),

                  // Step 3
                  _buildStepCard(
                    number: '3',
                    title: 'Tukar Hadiah',
                    description: 'Kumpulkan poin sebanyak mungkin dan tukarkan dengan hadiah menarik di menu tukar poin.',
                    icon: Icons.card_giftcard_rounded,
                    color: const Color(0xFFFF7043),
                    illustration: Icons.redeem_rounded,
                  ),

                  const SizedBox(height: 25),

                  // Tips Card
                  _buildTipsCard(colorHijau),

                  const SizedBox(height: 100), // Ruang agar tidak tertutup navbar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF49A7A2).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF49A7A2),
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cara Menggunakan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Pelajari cara melaporkan sampah, mengumpulkan poin, dan menukar hadiah.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String number,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required IconData illustration,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(illustration, color: color, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded, color: Color(0xFF49A7A2), size: 20),
              const SizedBox(width: 10),
              const Text(
                'Tips & Trik',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildTipItem('Foto sampah dengan jelas', primaryColor),
          _buildTipItem('Pastikan lokasi terlihat di foto', primaryColor),
          _buildTipItem('Berikan deskripsi detail', primaryColor),
          _buildTipItem('Rajin lapor untuk dapat banyak poin!', primaryColor),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- CLIPPERS GELOMBANG (Sama Persis dengan Laporkan Sampah) ---
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