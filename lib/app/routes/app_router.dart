import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/controllers/auth_controller.dart';
import 'route_names.dart';
import 'auth_routes.dart';
import 'dashboard_routes.dart';
import 'learning_routes.dart';
import 'quiz_routes.dart';
import 'flashcard_routes.dart';
import 'chat_routes.dart';
import 'youtube_routes.dart';
import 'news_routes.dart';
import 'grammar_routes.dart';
import 'profile_routes.dart';

class AppRouter {
  static GoRouter create(AuthController session) => GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: session,
    debugLogDiagnostics: kDebugMode,
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Lỗi Route')),
      body: Center(
        child: Text(
          'Không tìm thấy: ${state.matchedLocation}\nLỗi: ${state.error}',
          textAlign: TextAlign.center,
        ),
      ),
    ),

    redirect: (context, state) => session.redirect(state.matchedLocation),

    routes: [
      ...authRoutes(session),
      ...dashboardRoutes(session),
      ...learningRoutes(session),
      ...quizRoutes(session),
      ...flashcardRoutes(session),
      ...chatRoutes(session),
      ...youtubeRoutes(session),
      ...newsRoutes(session),
      ...grammarRoutes(session),
      ...profileRoutes(session),
    ],
  );
}
