import '../../data/repositories/admin_repository.dart';
import '../../presentation/controllers/admin_controller.dart';
import 'package:http/http.dart' as http;
import '../../data/repositories/news_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/remote/chat_service.dart';
import '../../data/datasources/remote/google_signin_service.dart';
import '../../data/datasources/remote/translation_service.dart';
import '../../data/datasources/remote/user_service.dart';
import '../../data/datasources/remote/youtube_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/flashcard_repository.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/controllers/chat_controller.dart';
import '../../presentation/controllers/flashcard_controller.dart';
import '../../presentation/controllers/friend_controller.dart';
import '../../presentation/controllers/grammar_controller.dart';
import '../../presentation/controllers/home_controller.dart';
import '../../presentation/controllers/lesson_controller.dart';
import '../../presentation/controllers/news_controller.dart';
import '../../presentation/controllers/quiz_controller.dart';
import '../../presentation/controllers/user_controller.dart';
import '../../presentation/controllers/youtube_controller.dart';

final getIt = GetIt.instance;

/// Composition root: GetIt owns services; GetX owns session UI controllers.
Future<void> initDependencies() async {
  if (getIt.isRegistered<AuthController>()) return;
  final preferences = await SharedPreferences.getInstance();
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  getIt.registerSingleton<FirebaseAuth>(auth);
  getIt.registerSingleton<FirebaseFirestore>(firestore);
  getIt.registerLazySingleton(
    () => UserRepository(firestore: firestore, auth: auth),
  );
  getIt.registerLazySingleton(
    () => LessonRepository(firestore: firestore, auth: auth),
  );
  getIt.registerLazySingleton(() => QuizRepository(firestore: firestore));
  getIt.registerLazySingleton(
    () => FlashcardRepository(firestore: firestore, auth: auth),
  );
  getIt.registerLazySingleton(() => ChatService(firestore: firestore));
  getIt.registerLazySingleton(() => UserService(firestore: firestore));
  getIt.registerLazySingleton<http.Client>(
    () => http.Client(),
    dispose: (client) => client.close(),
  );
  getIt.registerLazySingleton(
    () => NewsRepository(client: getIt<http.Client>()),
  );
  getIt.registerLazySingleton(
    () => YoutubeService(
      client: getIt<http.Client>(),
      apiKey: dotenv.env['YOUTUBE_API_KEY'] ?? '',
    ),
  );
  getIt.registerLazySingleton(
    () => TranslationService(apiKey: dotenv.env['GEMINI_API_KEY'] ?? ''),
  );
  getIt.registerLazySingleton(
    () => GoogleAuthService(
      auth: auth,
      googleSignIn: GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: kIsWeb ? dotenv.env['CLIENT_ID'] : null,
      ),
    ),
  );
  getIt.registerLazySingleton(
    () => AuthRepository(
      auth: auth,
      users: getIt<UserRepository>(),
      google: getIt<GoogleAuthService>(),
    ),
  );
  getIt.registerLazySingleton(() => AdminRepository(firestore: firestore));
  getIt.registerFactory(
    () => AdminController(
      repository: getIt<AdminRepository>(),
      auth: getIt<AuthRepository>(),
    ),
  );
  getIt.registerFactory(() => ChatController(repository: getIt<ChatService>()));
  getIt.registerFactory(
    () => FriendController(repository: getIt<UserService>()),
  );
  getIt.registerFactory(
    () => UserController(repository: getIt<UserRepository>()),
  );

  getIt.registerSingleton(
    AuthController(
      userIds: getIt<AuthRepository>().userIds,
      loadAdmin: getIt<UserRepository>().isAdmin,
      resetControllers: resetSessionControllers,
      hasSeenOnboarding: preferences.getBool('hasSeenOnboarding') ?? false,
      saveOnboarding: () async {
        await preferences.setBool('hasSeenOnboarding', true);
      },
    ),
    dispose: (controller) => controller.dispose(),
  );
}

/// Only these GetX objects belong to a session. Route-local Provider objects
/// are disposed by their route, and services live until application shutdown.
Future<void> resetSessionControllers() async {
  await Get.delete<HomeController>(force: true);
  await Get.delete<LearnController>(force: true);
  await Get.delete<FlashcardController>(force: true);
  await Get.delete<QuizController>(force: true);
  await Get.delete<NewsController>(force: true);
  await Get.delete<YoutubeController>(force: true);
  await Get.delete<GrammarController>(force: true);
  Get.lazyPut(
    () => HomeController(repository: getIt<UserRepository>()),
    fenix: true,
  );
  Get.lazyPut(
    () => LearnController(repository: getIt<LessonRepository>()),
    fenix: true,
  );
  Get.lazyPut(
    () => FlashcardController(
      repository: getIt<FlashcardRepository>(),
      translationService: getIt<TranslationService>(),
    ),
    fenix: true,
  );
  Get.lazyPut(
    () => QuizController(repository: getIt<QuizRepository>()),
    fenix: true,
  );
  Get.lazyPut(
    () => NewsController(repository: getIt<NewsRepository>()),
    fenix: true,
  );
  Get.lazyPut(
    () => YoutubeController(service: getIt<YoutubeService>()),
    fenix: true,
  );
  Get.lazyPut(() => GrammarController(), fenix: true);
}
