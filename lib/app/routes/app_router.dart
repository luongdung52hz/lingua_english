// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/screens/chat/chat_screen.dart';
import '../../presentation/screens/flashcard/flash_study_screen.dart';
import '../../presentation/screens/learn/learn_screen.dart';
import '../../presentation/screens/pdf/pdf_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/flashcard/flash_create_screen.dart';
import '../../presentation/screens/flashcard/flashcard_detail_screen.dart';
import '../../presentation/screens/flashcard/folder_management_screen.dart';
import '../../presentation/screens/learn/lesson_detail_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/onboading/onboading_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/flashcard/flashcard_screen.dart';
import '../../presentation/screens/admin/admin_screen.dart';

import 'route_names.dart';

class AppRouter {
  // Helper: Kiểm tra admin
  static Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return doc.data()?['role'] == 'admin' || doc.data()?['isAdmin'] == true;
    } catch (e) {
      print('Error checking admin: $e');
      return false;
    }
  }

  static final GoRouter router = GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Lỗi Route')),
      body: Center(
        child: Text(
          'Không tìm thấy: ${state.matchedLocation}\nLỗi: ${state.error}',
          textAlign: TextAlign.center,
        ),
      ),
    ),

    redirect: (context, state) async {
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

      final isAuthRoute = [
        Routes.login,
        Routes.register,
        Routes.forgotPassword,
        Routes.onboarding,
      ].contains(state.matchedLocation);

      // Chưa login → chuyển về onboarding/login
      if (user == null && !isAuthRoute && state.matchedLocation != Routes.splash) {
        return hasSeenOnboarding ? Routes.login : Routes.onboarding;
      }

      // Đã login
      if (user != null) {
        final userIsAdmin = await isAdmin();

        // Admin → vào admin dashboard
        if (userIsAdmin && [
          Routes.login,
          Routes.register,
          Routes.forgotPassword,
          Routes.onboarding,
          Routes.home,
        ].contains(state.matchedLocation)) {
          return Routes.admin;
        }

        // User thường → vào home
        if (!userIsAdmin && [
          Routes.login,
          Routes.register,
          Routes.forgotPassword,
          Routes.onboarding,
        ].contains(state.matchedLocation)) {
          return Routes.home;
        }

        // Chặn user thường vào admin
        if (!userIsAdmin && state.matchedLocation == Routes.admin) {
          return Routes.home;
        }
      }

      return null;
    },

    routes: [
      // SPLASH
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // AUTH
      GoRoute(path: Routes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (context, state) => const RegisterScreen()),
      GoRoute(path: Routes.forgotPassword, builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: Routes.onboarding, builder: (context, state) => const OnboardingScreen()),

      // MAIN
      GoRoute(path: Routes.home, builder: (context, state) => const HomeScreen()),
      GoRoute(path: Routes.admin, builder: (context, state) => const AdminScreen()),
      GoRoute(path: Routes.pdf, builder: (context, state) => const PdfUploadPage()),

      // LEARN
      GoRoute(
        path: Routes.learn,
        builder: (context, state) => const LearnScreen(),
        routes: [
          GoRoute(
            path: 'detail/:lessonId',
            builder: (context, state) => LessonDetailScreen(
              lessonId: state.pathParameters['lessonId']!,
            ),
          ),
        ],
      ),

      // FLASHCARDS – ĐÃ SỬA HOÀN HẢO!
      GoRoute(
        path: Routes.flashcards,
        builder: (context, state) => const FlashcardListScreen(),
        routes: [
          // Chi tiết 1 thẻ
          GoRoute(
            path: 'detail/:id',
            builder: (context, state) => FlashcardDetailScreen(
              id: state.pathParameters['id']!,
            ),
          ),
          // Tạo thẻ mới
          GoRoute(
            path: 'create',
            builder: (context, state) => const FlashcardCreateScreen(),
          ),
          // HỌC HÀNG LOẠT – MỚI!
          GoRoute(
            path: 'study',
            builder: (context, state) => const FlashcardStudyScreen(),
          ),
          // Quản lý thư mục
          GoRoute(
            path: 'folders',
            builder: (context, state) => const FolderManagementScreen(),
          ),
        ],
      ),

      // CHAT
      GoRoute(
        path: Routes.chat,
        builder: (context, state) => const ChatScreen(),
        routes: [
          GoRoute(path: 'room', builder: (context, state) => const Placeholder()),
        ],
      ),

      // AI
      GoRoute(path: Routes.aiChat, builder: (context, state) => const Placeholder()),
      GoRoute(path: Routes.aiCorrection, builder: (context, state) => const Placeholder()),

      // PROFILE
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(path: 'settings', builder: (context, state) => const Placeholder()),
        ],
      ),
    ],
  );
}