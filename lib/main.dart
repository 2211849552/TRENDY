import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart'; // استدعاء شاشة تسجيل الدخول

void main() {
  runApp(const MatajariApp());
}

class MatajariApp extends StatelessWidget {
  const MatajariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'متجري',
      debugShowCheckedModeBanner: false,
      // Dark Theme Configuration
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1220),
        primaryColor: const Color(0xFF3B82F6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.cairoTextTheme(
          ThemeData.dark().textTheme,
        ),
        useMaterial3: true,
      ),
      // RTL Support
      locale: const Locale('ar', 'AE'),
      supportedLocales: const [
        Locale('ar', 'AE'),
      ],
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // الانتقال بعد 3 ثواني إلى شاشة تسجيل الدخول
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0061FF), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.storefront_outlined, 
                    size: 80,
                    color: Color(0xFF0061FF),
                  ),
                  Positioned(
                    top: 25,
                    right: 25,
                    child: Icon(
                      Icons.star,
                      size: 20,
                      color: Colors.amber, 
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'متجري',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'منصة التسوق الإلكتروني',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(),
                const SizedBox(width: 10),
                _buildDot(),
                const SizedBox(width: 10),
                _buildDot(),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
      ),
    );
  }
}
