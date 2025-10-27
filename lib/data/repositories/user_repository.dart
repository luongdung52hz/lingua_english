import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = GetIt.I<FirebaseFirestore>();
  final String userId = GetIt.I<FirebaseAuth>().currentUser?.uid ?? '';

  Future<UserModel?> loadUser() async {
    if (userId.isEmpty) return null;
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data()!); // Parse thành model
    }
    return null;
  }

  Future<void> createDefaultUser({
    required String name,
    required String email,
  }) async {
    if (userId.isEmpty) return;
    final newUser = UserModel(
      uid: userId,
      name: name,
      email: email,
      level: 'A1',
      progress: 0.0,
      completedLessons: 0,
      totalLessons: 5,
      score: 0,
      dailyCompleted: 0,
      targetDaily: 5,
      dailyStreak: 0,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );
    await _firestore.collection('users').doc(userId).set(newUser.toJson());
  }

  Future<void> updateUserProgress({
    required int newCompleted,
    required int newDailyCompleted,
    required int newTotal,
    required int newScore,
    int newStreak = 0,
  }) async {
    if (userId.isEmpty) return;
    await _firestore.collection('users').doc(userId).update({
      'completedLessons': newCompleted,
      'dailyCompleted': newDailyCompleted,
      'totalLessons': newTotal,
      'score': newScore,
      'dailyStreak': newStreak,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}