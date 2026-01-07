import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart'; // WAJIB: Import ini
import 'dart:convert';
import 'register.dart';
import 'dashboard.dart';
import 'admin_page.dart';
import 'forgot_password.dart'; // Pastikan file ini ada

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- 1. INISIALISASI GOOGLE SIGN IN ---
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  // --- 2. LOGIKA LOGIN MANUAL (DATABASE) ---
  Future<void> _login() async {
    if (_identifierController.text.isEmpty || _passwordController.text.isEmpty) {
      _showCustomDialog(title: "Peringatan", message: "Lengkapi data Anda.", isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("http://192.168.0.179/aplikasisampah/login.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"identifier": _identifierController.text, "password": _passwordController.text}),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        var userData = data['user'];
        if (mounted) _showLoginSuccess(userData['name'], userData['id'].toString(), userData['role'].toString());
      } else {
        _showCustomDialog(title: "Gagal", message: data['message'] ?? "Email/Password salah", isError: true);
      }
    } catch (e) {
      debugPrint("ERROR LOGIN MANUAL: $e");
      _showCustomDialog(title: "Error", message: "Gagal terhubung ke server.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 3. LOGIKA LOGIN GOOGLE (BARU) ---
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      // A. Trigger Pop-up Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User batal login
        setState(() => _isLoading = false);
        return;
      }

      // B. Ambil data user
      String email = googleUser.email;
      String nama = googleUser.displayName ?? "User Google";

      // C. Kirim ke PHP
      await _loginToBackendWithGoogle(email, nama);

      // D. Logout sesi Google (Opsional, agar bisa ganti akun lain kali)
      _googleSignIn.disconnect();

    } catch (error) {
      debugPrint("Google Login Error: $error");
      _showCustomDialog(title: "Error", message: "Gagal login Google. Cek koneksi internet & SHA-1.", isError: true);
      setState(() => _isLoading = false);
    }
  }

  // --- 4. KIRIM DATA GOOGLE KE SERVER PHP ---
  Future<void> _loginToBackendWithGoogle(String email, String nama) async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.0.179/aplikasisampah/login_google.php"), // Pastikan file ini ada di htdocs
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "nama": nama,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        var userData = data['user'];
        if (mounted) _showLoginSuccess(userData['name'], userData['id'].toString(), userData['role'].toString());
      } else {
        _showCustomDialog(title: "Gagal", message: "Gagal memproses akun Google.", isError: true);
      }
    } catch (e) {
      debugPrint("ERROR ASLI: $e");
      _showCustomDialog(title: "Error", message: "Koneksi ke server bermasalah.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLoginSuccess(String name, String userId, String role) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          Navigator.pop(context);
          Widget targetPage = (role.toLowerCase() == 'admin') ? const AdminPage() : DashboardPage(name: name, userId: userId);
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => targetPage));
        });
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle, color: Color(0xFF49A7A2), size: 70),
              const SizedBox(height: 15),
              Text("Halo, $name!", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Text("Login Berhasil!", style: TextStyle(color: Colors.grey)),
            ]),
          ),
        );
      },
    );
  }

  void _showCustomDialog({required String title, required String message, bool isError = false}) {
    showDialog(context: context, builder: (context) => AlertDialog(title: Text(title), content: Text(message)));
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
                    // Logo Branding
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Row(children: [
                        const Icon(Icons.eco, color: Colors.white, size: 28),
                        const SizedBox(width: 8),
                        const Text("CleanCampus", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    const Text("LOGIN", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  ],
                ),
              ),
            ),
          ),

          // 4. Konten Form
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.32),

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
                        _buildInputField(controller: _identifierController, hint: "Email atau Username", icon: Icons.person_outline),
                        const SizedBox(height: 15),
                        _buildInputField(controller: _passwordController, hint: "Password", icon: Icons.lock_outline, isPassword: true),

                        // --- TOMBOL FORGOT PASSWORD (SUDAH DIPERBAIKI) ---
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Navigasi ke halaman Forgot Password
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ForgotPasswordPage())
                              );
                            },
                            child: const Text("Forgot Password?", style: TextStyle(color: Color(0xFF8B6E4E), fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                        // -------------------------------------------------

                        const SizedBox(height: 15),

                        // TOMBOL LOGIN MANUAL
                        SizedBox(
                          width: 180,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B6E4E), shape: const StadiumBorder(), elevation: 5),
                            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Login", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),

                        const SizedBox(height: 25),
                        const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("Or sign with", style: TextStyle(color: Colors.grey, fontSize: 12))), Expanded(child: Divider())]),
                        const SizedBox(height: 15),

                        // --- TOMBOL GOOGLE KLIKABLE ---
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
                            // Menggunakan Gambar Logo Google Resmi (Network) agar lebih bagus
                            child: Image.network(
                              "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png",
                              height: 35, width: 35,
                              // Jika gagal load gambar (offline), pakai icon mobile data sebagai fallback
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata_rounded, color: Colors.red, size: 40),
                            ),
                          ),
                        ),
                        // ------------------------------------------

                        const SizedBox(height: 20),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Text("Don't have account? ", style: TextStyle(fontSize: 13, color: Colors.grey)),
                          GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())), child: const Text("Register", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13))),
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
      decoration: BoxDecoration(color: const Color(0xFFF0E5D8).withOpacity(0.5), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF8B6E4E), width: 1.2)),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: const Color(0xFF8B6E4E), size: 20), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16)),
      ),
    );
  }
}

// Clippers
class TopWaveClipper extends CustomClipper<Path> {
  @override Path getClip(Size size) { var path = Path(); path.lineTo(0, size.height - 50); path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height - 25); path.quadraticBezierTo(size.width * 0.75, size.height - 50, size.width, size.height - 5); path.lineTo(size.width, 0); path.close(); return path; }
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
class MiddleWaveClipper extends CustomClipper<Path> {
  @override Path getClip(Size size) { var path = Path(); path.lineTo(0, size.height - 30); path.quadraticBezierTo(size.width * 0.5, size.height + 35, size.width, size.height - 35); path.lineTo(size.width, 0); path.close(); return path; }
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
class BottomWaveClipper extends CustomClipper<Path> {
  @override Path getClip(Size size) { var path = Path(); path.lineTo(0, size.height - 10); path.quadraticBezierTo(size.width * 0.5, size.height + 60, size.width, size.height); path.lineTo(size.width, 0); path.close(); return path; }
  @override bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}