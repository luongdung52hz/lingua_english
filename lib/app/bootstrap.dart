import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../firebase_options.dart';
import '../presentation/controllers/auth_controller.dart';
import 'di/dependency_injection.dart';
import 'routes/app_router.dart';

Future<GoRouter> bootstrap() async {
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  await initDependencies();
  return AppRouter.create(getIt<AuthController>());
}
