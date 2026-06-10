import 'dart:async';

import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import 'models/auth_session.dart';
import 'services/firebase_bootstrap.dart';
import 'theme/app_colors.dart';
import 'widgets/trendy_brand.dart';

/// يبدأ تهيئة Firebase في الخلفية دون تأخير الإقلاع.
final Future<void> splashBootstrapFuture = const FirebaseBootstrap().init();

/// شاشة إقلاع — التصميم الكامل (شعار + Trendy + SHOP. STYLE. TRENDY.).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _splashDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    unawaited(_leaveAfterReady());
  }

  Future<void> _leaveAfterReady() async {
    await Future.wait([
      splashBootstrapFuture,
      Future<void>.delayed(_splashDuration),
    ]);
    if (!mounted) return;

    final session = AuthSession.instance;
    if (session.isAuthenticated) {
      final name = session.user?.name;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            userName: (name != null && name.isNotEmpty) ? name : 'Trendy',
          ),
        ),
      );
      return;
    }

    if (session.isGuest) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen(isGuest: true)),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.splashBranding,
      child: Center(
        child: Image.asset(
          TrendyAssets.logoSplash,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          width: double.infinity,
          height: double.infinity,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
