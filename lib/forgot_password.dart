import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Pastikan import ini ada
import 'dart:convert'; // Pastikan import ini ada
import 'reset_password.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _checkEmailAndNavigate() async {
    if (_emailController.text.isEmpty) {
      _showSnack("Harap isi email Anda", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Pastikan check_email.php sudah dibuat di folder htdocs/aplikasisampah/
      final response = await http.post(
        Uri.parse("http://192.168.0.179/aplikasisampah/check_email.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": _emailController.text}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordPage(email: _emailController.text),
            ),
          );
        }
      } else {
        _showSnack("Email tidak terdaftar!", Colors.red);
      }
    } catch (e) {
      debugPrint("Error: $e");
      _showSnack("Gagal terhubung ke server", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF3E9D9),
      // --- PERBAIKAN UTAMA: GUNAKAN APPBAR TRANSPARAN ---
      extendBodyBehindAppBar: true, // Agar background wave bisa naik ke atas
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparan
        elevation: 0, // Tidak ada bayangan
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // --------------------------------------------------

      body: Stack(
        children: [
          // 1. Background Waves
          ClipPath(clipper: BottomWaveClipper(), child: Container(height: screenHeight * 0.38, color: const Color(0xFF5AB1A9).withOpacity(0.5))),
          ClipPath(clipper: MiddleWaveClipper(), child: Container(height: screenHeight * 0.34, color: const Color(0xFF3B8A84))),

          // 2. Header Content
          ClipPath(
            clipper: TopWaveClipper(),
            child: Container(
              height: screenHeight * 0.28,
              width: double.infinity, // Pastikan lebar penuh agar text center
              decoration: const BoxDecoration(color: Color(0xFF49A7A2)),
              child: const SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Tengahkan isi secara vertikal
                  children: [
                    // Text Judul
                    Text("FORGOT", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    Text("PASSWORD", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ),
            ),
          ),

          // 3. Scrollable Form
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.30), // Turunkan posisi Card

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_reset, color: Color(0xFF8B6E4E), size: 60),
                        const SizedBox(height: 15),
                        const Text(
                          "Masukkan email Anda. Kami akan mengecek ketersediaan akun Anda.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 25),

                        // Input Email
                        Container(
                          decoration: BoxDecoration(color: const Color(0xFFF0E5D8).withOpacity(0.5), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF8B6E4E), width: 1.2)),
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(hintText: "Email Address", prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF8B6E4E), size: 20), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 16)),
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Tombol Lanjut
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _checkEmailAndNavigate,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B6E4E), shape: const StadiumBorder(), elevation: 5),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Lanjut ke Reset Password", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Clippers (Tetap sama)
class TopWaveClipper extends CustomClipper<Path> { @override Path getClip(Size size) { var path = Path(); path.lineTo(0, size.height - 50); path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height - 25); path.quadraticBezierTo(size.width * 0.75, size.height - 50, size.width, size.height - 5); path.lineTo(size.width, 0); path.close(); return path; } @override bool shouldReclip(CustomClipper<Path> oldClipper) => false; }
class MiddleWaveClipper extends CustomClipper<Path> { @override Path getClip(Size size) { var path = Path(); path.lineTo(0, size.height - 30); path.quadraticBezierTo(size.width * 0.5, size.height + 35, size.width, size.height - 35); path.lineTo(size.width, 0); path.close(); return path; } @override bool shouldReclip(CustomClipper<Path> oldClipper) => false; }
class BottomWaveClipper extends CustomClipper<Path> { @override Path getClip(Size size) { var path = Path(); path.lineTo(0, size.height - 10); path.quadraticBezierTo(size.width * 0.5, size.height + 60, size.width, size.height); path.lineTo(size.width, 0); path.close(); return path; } @override bool shouldReclip(CustomClipper<Path> oldClipper) => false; }