import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF3E9D9), // Background Krem
      body: Stack(
        children: [
          // --- BACKGROUND WAVES (Hanya Atas) ---
          ClipPath(
            clipper: TopWaveClipper(),
            child: Container(
              height: screenHeight * 0.38, // Tinggi gelombang atas
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF49A7A2), Color(0xFF3B8A84)],
                ),
              ),
            ),
          ),

          // --- KONTEN UTAMA ---
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // 1. AREA LOGO & JUDUL (Di dalam area Hijau)
                  SizedBox(height: screenHeight * 0.08), // Jarak dari atas

                  const Icon(
                    Icons.eco_rounded,
                    size: 90,
                    color: Colors.white,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "CleanCampus",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),

                  // 2. JARAK PEMISAH
                  // Mendorong Slogan ke area Krem yang bersih
                  SizedBox(height: screenHeight * 0.15),

                  // 3. SLOGAN
                  const Text(
                    "Kampus Bersih, Pikiran Jernih.\nJaga lingkungan kita mulai hari ini.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B6E4E), // Warna Coklat
                      height: 1.5,
                    ),
                  ),

                  // 4. AREA TOMBOL
                  const SizedBox(height: 60),

                  // Tombol Login
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B6E4E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Tombol Register
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterPage()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF8B6E4E), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Colors.white.withOpacity(0.5),
                      ),
                      child: const Text(
                        "Register",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B6E4E),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- CLIPPERS (Hanya TopWave) ---

class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);

    // Lengkungan landai ke atas kanan
    path.quadraticBezierTo(
        size.width * 0.5, size.height + 20,
        size.width, size.height - 60
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}