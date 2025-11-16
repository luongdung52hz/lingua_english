// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learn_english/presentation/screens/quiz/quiz_create_screen.dart';
import 'package:learn_english/presentation/screens/quiz/quiz_detail_screen.dart';
import 'package:learn_english/presentation/screens/quiz/quiz_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/news_article_model.dart';
import '../../data/models/youtube_video_model.dart';
import '../../presentation/controllers/chat_controller.dart';
import '../../presentation/controllers/friend_controller.dart';
import '../../presentation/controllers/grammar_controller.dart';
import '../../presentation/controllers/news_controller.dart'; // ✅ THÊM: Import NewsController nếu chưa
import '../../presentation/screens/chat/chat_list_screen.dart';
import '../../presentation/screens/chat/chat_screen.dart';
import '../../presentation/screens/chat/friend_screen.dart';
import '../../presentation/screens/chat/quiz_duel_screen.dart';
import '../../presentation/screens/flashcard/flash_study_screen.dart';
import '../../presentation/screens/grammar/grammar_detail_screen.dart';
import '../../presentation/screens/grammar/grammar_list_topics_screen.dart';
import '../../presentation/screens/grammar/grammar_topics_screen.dart';
import '../../presentation/screens/learn/learn_screen.dart';
import '../../presentation/screens/news/daily_news.dart';
import '../../presentation/screens/news/news_detail_screen.dart'; // ✅ THÊM: Import NewsDetailScreen
import '../../presentation/screens/pdf/pdf_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/flashcard/flash_create_screen.dart';
import '../../presentation/screens/flashcard/flashcard_detail_screen.dart';
import '../../presentation/screens/flashcard/folder_management_screen.dart';
import '../../presentation/screens/learn/lesson_detail_screen.dart';
import '../../presentation/screens/quiz/widgets/quiz_taking.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/onboading/onboading_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/flashcard/flashcard_screen.dart';
import '../../presentation/screens/admin/admin_screen.dart';

// Thêm imports cho YouTube module
import '../../presentation/screens/youtube/video_play_screen.dart';
import '../../presentation/screens/youtube/youtube_channel_screen.dart';
import '../../presentation/screens/youtube/youtube_playlists_video_screen.dart';
import '../../presentation/screens/youtube/youtube_videos_screen.dart';

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

      if (user == null && !isAuthRoute && state.matchedLocation != Routes.splash) {
        return hasSeenOnboarding ? Routes.login : Routes.onboarding;
      }

      if (user != null) {
        final userIsAdmin = await isAdmin();

        if (userIsAdmin && [
          Routes.login,
          Routes.register,
          Routes.forgotPassword,
          Routes.onboarding,
          Routes.home,
        ].contains(state.matchedLocation)) {
          return Routes.admin;
        }

        if (!userIsAdmin && [
          Routes.login,
          Routes.register,
          Routes.forgotPassword,
          Routes.onboarding,
        ].contains(state.matchedLocation)) {
          return Routes.home;
        }

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

      // QUIZ
      GoRoute(
        path: Routes.quiz,
        builder: (context, state) => QuizListScreen(),
        routes: [
          GoRoute(
            path: 'detail/:id',
            builder: (context, state) => QuizDetailScreen(
              quizId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'taking/:id',
            builder: (context, state) => QuizTakingScreen(quizId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreateQuizScreen(),
          ),

        ],
      ),

      // FLASHCARDS
      GoRoute(
        path: Routes.flashcards,
        builder: (context, state) => const FlashcardListScreen(),
        routes: [
          GoRoute(
            path: 'detail/:id',
            builder: (context, state) => FlashcardDetailScreen(
              id: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'create',
            builder: (context, state) => const FlashcardCreateScreen(),
          ),
          GoRoute(
            path: 'study',
            builder: (context, state) => const FlashcardStudyScreen(),
          ),
          GoRoute(
            path: 'folders',
            builder: (context, state) => const FolderManagementScreen(),
          ),
        ],
      ),

      // CHAT
      GoRoute(
        path: Routes.chat,
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => ChatController(),
          child: const ChatListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'friends',
            builder: (context, state) => ChangeNotifierProvider<FriendController>(
              create: (_) => FriendController(),
              child: FriendsScreen(
                currentUid: FirebaseAuth.instance.currentUser?.uid ?? '',
              ),
            ),
          ),
          //  FIX: Bỏ QuizController khỏi Provider
          GoRoute(
            path: 'room/:roomId',
            builder: (context, state) => ChangeNotifierProvider(
              create: (_) => ChatController(),
              child: ChatScreen(
                roomId: state.pathParameters['roomId']!,
                currentUid: FirebaseAuth.instance.currentUser?.uid ?? '',
              ),
            ),
          ),
        ],
      ),

      //VIDEO
      GoRoute(
        path: '/youtube/channels',
        builder: (context, state) => const YoutubeChannelsScreen(),
      ),
      GoRoute(
        path: '/youtube/playlists',
        builder: (context, state) => const YoutubePlaylistsScreen(),
      ),
      GoRoute(
        path: '/youtube/videos',
        builder: (context, state) => const YoutubeVideosScreen(),
      ),
      GoRoute(
        path: '/youtube/player/:videoId',
        builder: (context, state) {
          final videoId = state.pathParameters['videoId']!;
          return YoutubePlayerScreen(videoId: videoId);
        },
      ),

      //NEWS - ✅ FIX: Nested routes đúng, inject controller, và builder detail đúng NewsDetailScreen
      GoRoute(
        path: '/news',
        builder: (context, state) {
          Get.put(DailyNewsSection()); // Inject controller
          return const DailyNewsSection();
        },
        routes: [
          GoRoute(
            path: '/detail', // Không params, dùng extra cho article
            builder: (context, state) {
              final article = state.extra as NewsArticle; // Từ onTap push
              return NewsDetailScreen(article: article); // ✅ FIX: Return NewsDetailScreen với extra
            },
          ),
        ],
      ),

      //GRAMMAR
      GoRoute(
        path: Routes.grammar,
        builder: (context, state) {
          Get.put(GrammarController());
          return  GrammarTopicsScreen(); // Cấp 1: Danh sách topics
        },
        routes: [
          GoRoute(
            path: 'subtopics/:topicId', // ✅ THÊM: Route mới cho cấp 2 - danh sách subtopics
            builder: (context, state) {
              Get.put(GrammarController());
              return GrammarSubTopicsScreen(
                topicId: state.pathParameters['topicId']!,
              );
            },
          ),
          GoRoute(
            path: 'detail/:topicId/:subTopicId', // Cấp 3: Chi tiết sections
            builder: (context, state) {
              Get.put(GrammarController());
              return GrammarDetailScreen(
                topicId: state.pathParameters['topicId']!,
                subTopicId: state.pathParameters['subTopicId']!,
              );
            },
          ),
        ],
      ),
      // AI
      GoRoute(path: Routes.aiChat, builder: (context, state) => const Placeholder()),
      GoRoute(path: Routes.aiChat, builder: (context, state) => const Placeholder()),

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