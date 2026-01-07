import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// Tidak perlu import login.dart di sini, kita pakai Navigator.pop saja

class ResetPasswordPage extends StatefulWidget {
  final String email; // Menerima email dari halaman sebelumnya
  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  bool _isLoading = false;

  Future<void> _updatePassword() async {
    if (_passController.text.isEmpty || _confirmPassController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password tidak boleh kosong!")));
      return;
    }

    if (_passController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konfirmasi password tidak sama!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("http://192.168.0.179/aplikasisampah/update_password.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email, // Email yang dikirim dari halaman Forgot Password
          "new_password": _passController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text("Berhasil"),
              content: const Text("Password Anda telah diperbarui. Silakan Login dengan password baru."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Tutup Dialog
                    Navigator.pop(context); // Tutup Reset Page
                    Navigator.pop(context); // Tutup Forgot Page -> BALIK KE LOGIN
                  },
                  child: const Text("OK"),
                )
              ],
            ),
          );
        }
      } else {
        _showError(data['message']);
      }
    } catch (e) {
      _showError("Gagal terhubung ke server.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E9D9),
      appBar: AppBar(
        title: const Text("Buat Password Baru"),
        backgroundColor: const Color(0xFF49A7A2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Text("Reset untuk: ${widget.email}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: "Password Baru",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _confirmPassController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: "Ulangi Password Baru",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updatePassword,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B6E4E)),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Simpan Password", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}