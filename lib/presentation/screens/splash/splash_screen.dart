import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../app/routes/route_names.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final FirebaseAuth _auth = GetIt.I<FirebaseAuth>();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();

    // Tạo animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Fade in animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Scale animation
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Bắt đầu animation
    _controller.forward();

    // Delay chuyển trang
    Timer(const Duration(seconds: 3), () async {
      try {
        // ✅ CHỈ LOGOUT GOOGLE (không logout Firebase)
        // Điều này xóa cache Google nhưng giữ session Firebase cho Email/Password
        await _googleSignIn.signOut();
        print('🔓 Google account cache cleared');
      } catch (e) {
        print('⚠️ Google logout error: $e');
      }

      final prefs = await SharedPreferences.getInstance();
      final bool hasSeenOnboarding =
          prefs.getBool('hasSeenOnboarding') ?? false;
      final bool loggedIn = _auth.currentUser != null;

      if (mounted) {
        if (loggedIn) {
          // Đã login (Email/Password): Đi thẳng Home
          context.go(Routes.home);
        } else if (!hasSeenOnboarding) {
          // Chưa login và chưa seen onboarding: Đi Onboarding
          context.go(Routes.onboarding);
        } else {
          // Chưa login nhưng đã seen onboarding: Đi Login
          context.go(Routes.login);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo app
              Image.asset(
                'lib/resources/assets/images/logo_L_final.png',
                height: 120,
                width: 120,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}