import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:learn_english/data/datasources/remote/google_signin_service.dart';
import 'package:learn_english/presentation/controllers/quiz_controller.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../presentation/screens/auth/login_screen.dart';
import 'app/di/dependency_injection.dart';
import 'app/routes/app_router.dart';
import 'app/config/app.theme.dart';
import 'app/config/app_constants.dart';
import 'app/localization/app_localizations.dart';
import 'firebase_options.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'demo/lesson_demo_data.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  print(' .env loaded successfully');

  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Hive
  await Hive.initFlutter();
  // Đăng ký adapter ở đây nếu cần
  // Hive.registerAdapter(UserModelAdapter());
  await initDependencies();
  print(' AppRouter.router: ${AppRouter.router.toString()}');
  //await createAdmin();
  // Upload demo lessons to Firestore (bỏ comment để chạy)
  // await uploadDemoLessons();
  runApp(const MyApp());

}

// Trong main.dart hoặc script riêng
Future<void> createAdmin() async {
  final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: 'admin@gmail.com',
    password: '123456',
  );

  final adminUid = userCredential.user!.uid;
  await FirebaseFirestore.instance.collection('users').doc(adminUid).set({
    'uid': adminUid,
    'email': 'admin@gmail.com',
    'name': 'Admin',
    'role': 'admin',
    'level': 'A1',
    'progress': 0.0,
    'completedLessons': 0,
    'totalLessons': 100,
    'dailyCompleted': 0,
    'targetDaily': 5,
    'dailyStreak': 0,
    'score': 0,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  print('Admin created: UID = $adminUid');
}

// Future<void> uploadDemoLessons() async {
//   final firestore = FirebaseFirestore.instance;
//   final batch = firestore.batch();
//
//   final lessons = LessonDemoData.getAllLessons();
//
//   for (var lesson in lessons) {
//     final docRef = firestore.collection('lessons').doc(lesson.id);
//     batch.set(docRef, lesson.toJson());
//   }
//
//   try {
//     await batch.commit();
//     print(' Uploaded ${lessons.length} demo lessons to Firestore!');
//   } catch (e) {
//     print(' Error uploading lessons: $e');
//   }
// }


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('en'), Locale('vi')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: AppRouter.router,
    );
  }
}