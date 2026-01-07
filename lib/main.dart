import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'landing_page.dart'; // <--- IMPORT INI (File Baru)
import 'login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CleanCampus',

      // Scroll behavior untuk Web/Mouse drag
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF49A7A2),
          primary: const Color(0xFF49A7A2),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF49A7A2),
          foregroundColor: Colors.white,
        ),
      ),

      // --- PERUBAHAN DI SINI ---
      // Arahkan initialRoute ke halaman landing
      initialRoute: '/',

      routes: {
        '/': (context) => const LandingPage(), // Halaman awal baru
        '/login': (context) => const LoginPage(),
      },
      // -------------------------
    );
  }
}