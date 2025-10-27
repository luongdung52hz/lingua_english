import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../data/repositories/user_repository.dart';


final getIt = GetIt.instance;

Future<void> initDependencies() async {
  // Services
  getIt.registerLazySingleton<FirebaseAuth>(()=>FirebaseAuth.instance);
  getIt.registerLazySingleton(()=>FirebaseFirestore.instance);
  getIt.registerLazySingleton<LessonRepository>(() => LessonRepository());
  getIt.registerLazySingleton<UserRepository>(() => UserRepository());

}