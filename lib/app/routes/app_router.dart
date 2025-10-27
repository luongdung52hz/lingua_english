import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learn_english/presentation/screens/chat/chat_screen.dart';
import 'package:learn_english/presentation/screens/learn/learn_screen.dart';
import 'package:learn_english/presentation/screens/profile/profile_screen.dart';

// Import screens (chỉ import những cái cần, tránh lỗi nếu file chưa tồn tại)
import '../../presentation/screens/learn/lesson_detail_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/onboading/onboading_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
// Import các screen khác nếu đã có; nếu chưa, dùng Placeholder
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/flashcard/flashcard_screen.dart';
import '../../presentation/controllers/lesson_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'route_names.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: Routes.splash,  // An toàn, vì có builder
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => Scaffold(  // Handle lỗi route
      appBar: AppBar(title: const Text('Lỗi Route')),
      body: Center(
        child: Text('Không tìm thấy route: ${state.matchedLocation}\nLỗi: ${state.error}'),
      ),
    ),

    redirect: (context, state) async {
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      final isAuthRoute = state.matchedLocation == Routes.login ||
          state.matchedLocation == Routes.register ||
          state.matchedLocation == Routes.forgotPassword ||
          state.matchedLocation == Routes.onboarding;

      print('Redirect: User=${user?.email ?? 'null'}, Location=${state.matchedLocation}, hasSeenOnboarding=$hasSeenOnboarding');

      // Nếu chưa login và cố truy cập protected
      if (user == null && !isAuthRoute && state.matchedLocation != Routes.splash) {
        // Nếu chưa seen onboarding
        return hasSeenOnboarding ? Routes.login : Routes.onboarding;
      }
      // Nếu đã login, skip auth/onboarding về home
      if (user != null && (state.matchedLocation == Routes.login ||
          state.matchedLocation == Routes.onboarding ||
          state.matchedLocation == Routes.register ||
          state.matchedLocation == Routes.forgotPassword)) {
        return Routes.home;
      }
      return null;
    },

    routes: [
      /// SPLASH
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      /// REGISTER
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      /// FORGOTPASSWORD
      GoRoute(
        path: Routes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      /// ONBOARDING
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      /// HOME
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),

      /// AUTH
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      /// LEARN
      GoRoute(
        path: Routes.learn,
        builder: (context, state) => const LearnScreen(),
        routes: [
          GoRoute(
            path: 'detail/:lessonId',
            builder: (context, state) => LessonDetailScreen(lessonId: state.pathParameters['lessonId']!),
          ),
        ],
      ),
      /// FLASHCARDS
      GoRoute(
        path: Routes.flashcards,
        builder: (context, state) => const FlashcardScreen(),
        routes: [
          GoRoute(
            path: 'detail',
            builder: (context, state) => const Placeholder(),
          ),
        ],
      ),

      /// CHAT
      GoRoute(
        path: Routes.chat,
        builder: (context, state) => const ChatScreen(),
        routes: [
          GoRoute(
            path: 'room',
            builder: (context, state) => const Placeholder(),
          ),
        ],
      ),

      /// AI
      GoRoute(
        path: Routes.aiChat,
        builder: (context, state) => const Placeholder(),
      ),
      GoRoute(
        path: Routes.aiCorrection,
        builder: (context, state) => const Placeholder(),
      ),

      /// PROFILE
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) => const Placeholder(),
          ),
        ],
      ),
    ],
  );
}