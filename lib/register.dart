import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart'; // WAJIB: Import ini
import 'dart:convert';
import 'dashboard.dart';
import 'admin_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- 1. INISIALISASI GOOGLE SIGN IN ---
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  // --- 2. LOGIKA REGISTER MANUAL (DATABASE) ---
  Future<void> _register() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showCustomDialog(
        title: "Peringatan",
        message: "Lengkapi semua data untuk mendaftar.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("http://192.168.0.179/aplikasisampah/register.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": _nameController.text,
          "email": _emailController.text,
          "password": _passwordController.text,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        if (mounted) _showRegisterSuccess();
      } else {
        _showCustomDialog(
          title: "Registrasi Gagal",
          message: data['message'] ?? "Terjadi kesalahan.",
          isError: true,
        );
      }
    } catch (e) {
      _showCustomDialog(
        title: "Koneksi Error",
        message: "Gagal terhubung ke server. Periksa XAMPP Anda.",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 3. LOGIKA REGISTER DENGAN GOOGLE (BARU) ---
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      // A. Trigger Pop-up Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // B. Ambil data user
      String email = googleUser.email;
      String nama = googleUser.displayName ?? "User Google";

      // C. Kirim ke PHP (Pakai login_google.php karena dia otomatis register jika belum ada)
      await _registerWithGoogleBackend(email, nama);

      _googleSignIn.disconnect();

    } catch (error) {
      debugPrint("Google Register Error: $error");
      _showCustomDialog(title: "Error", message: "Gagal daftar via Google.", isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registerWithGoogleBackend(String email, String nama) async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.0.179/aplikasisampah/login_google.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "nama": nama,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        // Jika sukses via Google, langsung masuk ke Dashboard (Auto Login)
        var userData = data['user'];
        if (mounted) _navigateToDashboard(userData['name'], userData['id'].toString(), userData['role'].toString());
      } else {
        _showCustomDialog(title: "Gagal", message: "Gagal memproses akun Google.", isError: true);
      }
    } catch (e) {
      _showCustomDialog(title: "Error", message: "Koneksi ke server bermasalah.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Navigasi langsung jika pakai Google (Auto Login)
  void _navigateToDashboard(String name, String userId, String role) {
    Widget targetPage = (role.toLowerCase() == 'admin') ? const AdminPage() : DashboardPage(name: name, userId: userId);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => targetPage));
  }

  // Dialog sukses untuk Register Manual
  void _showRegisterSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          Navigator.pop(context); // Tutup dialog
          Navigator.pop(context); // Kembali ke halaman Login
        });
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars_rounded, color: Color(0xFF49A7A2), size: 80),
                SizedBox(height: 20),
                Text("Berhasil Daftar!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text("Akun Anda telah dibuat. Silakan login.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCustomDialog({required String title, required String message, bool isError = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: TextStyle(color: isError ? Colors.redAccent : const Color(0xFF49A7A2), fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF3E9D9),
      body: Stack(
        children: [
          // 1. Lapisan Gelombang Belakang
          ClipPath(
            clipper: BottomWaveClipper(),
            child: Container(
              height: screenHeight * 0.38,
              color: const Color(0xFF5AB1A9).withOpacity(0.5),
            ),
          ),

          // 2. Lapisan Gelombang Menengah
          ClipPath(
            clipper: MiddleWaveClipper(),
            child: Container(
              height: screenHeight * 0.34,
              color: const Color(0xFF3B8A84),
            ),
          ),

          // 3. Header Utama
          ClipPath(
            clipper: TopWaveClipper(),
            child: Container(
              height: screenHeight * 0.28,
              decoration: const BoxDecoration(color: Color(0xFF49A7A2)),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Row(children: [
                        const Icon(Icons.eco, color: Colors.white, size: 28),
                        const SizedBox(width: 8),
                        const Text("CleanCampus", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    const Text("Register", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  ],
                ),
              ),
            ),
          ),

          // 4. Form Register
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.32),

                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildInputField(
                            controller: _nameController,
                            hint: "Username",
                            icon: Icons.person_outline_rounded
                        ),
                        const SizedBox(height: 15),
                        _buildInputField(
                            controller: _emailController,
                            hint: "E-mail",
                            icon: Icons.email_outlined
                        ),
                        const SizedBox(height: 15),
                        _buildInputField(
                            controller: _passwordController,
                            hint: "Password",
                            icon: Icons.visibility_outlined,
                            isPassword: true
                        ),
                        const SizedBox(height: 25),

                        // Tombol Register Cokelat
                        SizedBox(
                          width: 180,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B6E4E),
                                shape: const StadiumBorder(),
                                elevation: 5
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Register", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), // Typography fixed
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("Or Continue with", style: TextStyle(color: Colors.grey, fontSize: 12))), Expanded(child: Divider())]),
                        const SizedBox(height: 15),

                        // --- TOMBOL GOOGLE (BARU) ---
                        GestureDetector(
                          onTap: _isLoading ? null : _handleGoogleSignIn,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                              color: Colors.white,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                            ),
                            child: Image.network(
                              "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png",
                              height: 35, width: 35,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata_rounded, color: Colors.red, size: 40),
                            ),
                          ),
                        ),
                        // -----------------------------

                        const SizedBox(height: 20),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Text("Already have an account? ", style: TextStyle(fontSize: 13, color: Colors.grey)),
                          GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text("Login", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13))
                          ),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFFF0E5D8).withOpacity(0.5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF8B6E4E), width: 1.2)
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF8B6E4E), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16)
        ),
      ),
    );
  }
}

// Clippers Identik dengan Login
class TopWaveClipper extends CustomClipper<Path> {
  @override Path getClip(Size size) { var path = Path(); path.lineTo(0, size.height - 50); path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height - 25); path.quadraticBezierTo(size.width * 0.75, size.height - 50, size.width, size.height - 5); path.lineTo(size.width, 0); path.close(); return path; }
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
class MiddleWaveClipper extends CustomClipper<Path> {
  @override Path getClip(Size size) { var path = Path(); path.lineTo(0, size.height - 30); path.quadraticBezierTo(size.width * 0.5, size.height + 35, size.width, size.height - 40); path.lineTo(size.width, 0); path.close(); return path; }
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
class BottomWaveClipper extends CustomClipper<Path> {
  @override Path getClip(Size size) { var path = Path(); path.lineTo(0, size.height - 10); path.quadraticBezierTo(size.width * 0.5, size.height + 60, size.width, size.height); path.lineTo(size.width, 0); path.close(); return path; }
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}