import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class LaporkanSampahPage extends StatefulWidget {
  final String userId;
  const LaporkanSampahPage({super.key, required this.userId});

  @override
  State<LaporkanSampahPage> createState() => _LaporkanSampahPageState();
}

class _LaporkanSampahPageState extends State<LaporkanSampahPage> {
  final List<XFile> _listGambar = [];
  final _picker = ImagePicker();
  final _beratController = TextEditingController();
  final _deskripsiController = TextEditingController();
  bool _isLoading = false;

  final Color colorHijau = const Color(0xFF49A7A2);
  final Color colorHijauGelap = const Color(0xFF3B8A84);
  final Color colorCream = const Color(0xFFF3E9D9);

  // --- MODIFIKASI: Menerima parameter source (Kamera/Galeri) ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50, // Kompresi gambar agar ringan
      );
      if (pickedFile != null) {
        setState(() => _listGambar.add(pickedFile));
      }
    } catch (e) {
      debugPrint("Gagal mengambil gambar: $e");
    }
  }

  void _removeImage(int index) => setState(() => _listGambar.removeAt(index));

  // --- MODIFIKASI: Fungsi Menampilkan Pilihan Kamera/Galeri ---
  void _showImageSourceOption() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Ambil Foto Dari",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionItem(
                    icon: Icons.camera_alt_rounded,
                    label: "Kamera",
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildOptionItem(
                    icon: Icons.photo_library_rounded,
                    label: "Galeri",
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: colorHijau.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorHijau, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _uploadLaporan() async {
    if (_listGambar.isEmpty || _beratController.text.isEmpty) {
      _showErrorDialog("Opps!", "Minimal sertakan 1 foto dan berat sampah ya.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Pastikan URL sesuai dengan konfigurasi server (Gunakan 10.0.2.2 untuk Emulator Android)
      var request = http.MultipartRequest("POST", Uri.parse("http://192.168.0.179/aplikasisampah/upload_report.php"));
      request.fields['user_id'] = widget.userId;
      request.fields['description'] = _deskripsiController.text;
      request.fields['weight'] = _beratController.text;

      for (var img in _listGambar) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
              'image[]',
              await img.readAsBytes(),
              filename: img.name
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
              'image[]',
              img.path
          ));
        }
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        _showSuccessDialog();
        // Reset form setelah berhasil
        setState(() {
          _listGambar.clear();
          _beratController.clear();
          _deskripsiController.clear();
        });
      } else {
        _showErrorDialog("Gagal", "Server merespon dengan kode: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog("Error", "Gagal terhubung ke server. Cek koneksi internet.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_rounded, color: colorHijau, size: 60),
        const SizedBox(height: 15),
        const Text("Berhasil Dikirim!", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("OKE"))
      ]),
    ));
  }

  void _showErrorDialog(String title, String msg) {
    showDialog(context: context, builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup"))
        ]
    ));
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
                    const Icon(Icons.eco, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    const Text("Laporkan Sampah", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ),
          ),

          // 2. KONTEN
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.13),

                  _buildInfoCard(),
                  const SizedBox(height: 20),

                  _buildSectionTitle("Tambahkan Foto Sampah"),
                  _buildImageArea(), // Widget area gambar yang sudah diperbarui
                  const SizedBox(height: 20),

                  _buildSectionTitle("Informasi Berat"),
                  _buildWeightInput(),
                  const SizedBox(height: 20),

                  _buildSectionTitle("Deskripsi (opsional)"),
                  _buildDescInput(),
                  const SizedBox(height: 30),

                  _buildSubmitButton(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Row(children: [
        Icon(Icons.info_outline, color: colorHijau, size: 20),
        const SizedBox(width: 10),
        const Expanded(
            child: Text(
                'Bantu jaga kebersihan kampus dengan melaporkan sampah yang kamu temukan.',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.3)
            )
        ),
      ]),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(alignment: Alignment.centerLeft, padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)));
  }

  // --- MODIFIKASI: Area Gambar dengan List Horizontal & Tombol Hapus ---
  Widget _buildImageArea() {
    return Column(
      children: [
        // Container Utama
        GestureDetector(
          onTap: _listGambar.isEmpty ? _showImageSourceOption : null, // Klik hanya aktif jika kosong
          child: Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: colorHijau.withOpacity(0.2)),
            ),
            child: _listGambar.isEmpty
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_rounded, color: colorHijau, size: 35),
                const SizedBox(height: 8),
                const Text("Ketuk untuk ambil foto", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            )
                : ListView.builder(
              padding: const EdgeInsets.all(10),
              scrollDirection: Axis.horizontal,
              itemCount: _listGambar.length + 1, // +1 untuk tombol tambah
              itemBuilder: (context, i) {
                // Tombol Tambah (+) di ujung list
                if (i == _listGambar.length) {
                  return GestureDetector(
                    onTap: _showImageSourceOption,
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                      ),
                      child: const Center(child: Icon(Icons.add_rounded, color: Colors.grey, size: 30)),
                    ),
                  );
                }

                // Item Foto dengan Tombol Hapus (X)
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: kIsWeb
                            ? Image.network(_listGambar[i].path, fit: BoxFit.cover, height: 140)
                            : Image.file(File(_listGambar[i].path), fit: BoxFit.cover, height: 140),
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 15,
                      child: GestureDetector(
                        onTap: () => _removeImage(i),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightInput() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: TextField(
          controller: _beratController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
              hintText: "Contoh: 2.5 Kg",
              prefixIcon: Icon(Icons.scale, color: colorHijau),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15)
          )
      ),
    );
  }

  Widget _buildDescInput() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: TextField(
          controller: _deskripsiController,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: "Tuliskan keterangan tambahan lokasi...",
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(15)
          )
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
        width: double.infinity, height: 50,
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorHijau, shape: const StadiumBorder()),
            onPressed: _isLoading ? null : _uploadLaporan,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Kirim Laporan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
        )
    );
  }
}

// Clippers (Tetap sama seperti sebelumnya)
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