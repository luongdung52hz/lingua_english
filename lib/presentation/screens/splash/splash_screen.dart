import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/routes/route_names.dart';
import '../../../resources/styles/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../presentation/screens/onboading/onboading_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final FirebaseAuth _auth = GetIt.I<FirebaseAuth>();

  @override
  void initState() {
    super.initState();

    // Tạo hiệu ứng quay
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    // Delay chuyển trang
    Timer(const Duration(seconds: 3), () async {
      final prefs = await SharedPreferences.getInstance();
      final bool hasSeenOnboarding =
          prefs.getBool('hasSeenOnboarding') ?? false;
      final bool loggedIn = _auth.currentUser != null;
      if (mounted) {
        if (loggedIn) {
          // Đã login: Đi thẳng Home (bỏ qua onboarding dù đã seen hay chưa)
          context.go(Routes.home);
        } else if (!hasSeenOnboarding) {
          // Chưa login và chưa seen onboarding: Đi Onboarding (lần đầu)
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

  // Hàm dựng các icon con xung quanh trung tâm
  List<Widget> _buildOrbitingIcons(double radius) {
    final icons = [
      'lib/resources/assets/icons/letter_e.svg',
      'lib/resources/assets/icons/letteran.svg',
      'lib/resources/assets/icons/letterchinese.svg',
      'lib/resources/assets/icons/letterkr2.svg',
      'lib/resources/assets/icons/letter_a.svg',
      // 'lib/resources/assets/icons/letter_s.svg',
      // 'lib/resources/assets/icons/letter_h.svg',
    ];

    return List.generate(icons.length, (index) {
      final angle = (2 * pi / icons.length) * index;

      return AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          final rotation = angle + _controller.value * 2 * pi;
          return Transform.translate(
            offset: Offset(radius * cos(rotation), radius * sin(rotation)),
            child: child,
          );
        },

        child: SvgPicture.asset(
          icons[index],
          height: 30,
          width: 30,
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = 80.0; // bán kính quay quanh trung tâm

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Icon trung tâm
                  Image.asset(
                    'lib/resources/assets/images/logo_2.png',
                    height: 140,
                    width: 140,

                  ),

                  // Các icon quay quanh
                  ..._buildOrbitingIcons(radius),
                ],
              ),


              const SizedBox(height: 360),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
              const SizedBox(height: 10),
              const Text(
                "Đang tải...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
