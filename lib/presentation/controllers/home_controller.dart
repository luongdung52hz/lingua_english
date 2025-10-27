import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import '../../data/models/user_model.dart';
import 'dart:async';

class HomeController extends GetxController {
  final FirebaseAuth _auth = GetIt.I<FirebaseAuth>();
  final FirebaseFirestore firestore = GetIt.I<FirebaseFirestore>();

  final RxDouble progressPercent = 0.0.obs;
  final RxInt completedLessons = 0.obs;
  final RxInt totalLessons = 0.obs;
  final RxInt score = 0.obs;
  final RxInt dailyCompleted = 0.obs;
  final RxInt targetDaily = 5.obs;
  final RxInt dailyStreak = 0.obs;
  final RxString userName = ''.obs;

  String get userId => _auth.currentUser?.uid ?? '';

  //  NEW: Stream subscription for real-time updates
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void onInit() {
    super.onInit();
    loadUserProgress();
    _listenToUserChanges(); // ⭐ Lsten to real-time changes
  }

  @override
  void onClose() {
    _userSubscription?.cancel(); //  Cancel subscription
    super.onClose();
  }

  ///  NEW: Listen to user document changes (real-time)
  void _listenToUserChanges() {
    if (userId.isEmpty) return;

    _userSubscription = firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final user = UserModel.fromJson(snapshot.data()!);
        _updateLocalState(user);
      }
    }, onError: (error) {
      print('❌ Error listening to user changes: $error');
    });
  }

  ///  NEW: Update local state from UserModel
  void _updateLocalState(UserModel user) {
    progressPercent.value = user.progress;
    completedLessons.value = user.completedLessons;
    totalLessons.value = user.totalLessons;
    score.value = user.score;
    dailyCompleted.value = user.dailyCompleted;
    targetDaily.value = user.targetDaily;
    dailyStreak.value = user.dailyStreak;
    userName.value = user.name;

    print('🔄 Home state updated: Daily ${user.dailyCompleted}/${user.targetDaily}, Streak: ${user.dailyStreak}');
  }

  Future<void> loadUserProgress() async {
    if (userId.isEmpty) return;

    try {
      final doc = await firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final user = UserModel.fromJson(doc.data()!);
        _updateLocalState(user);
      } else {
        // Tạo user mới với default
        final newUser = UserModel(
          uid: userId,
          name: _auth.currentUser?.displayName ?? 'User',
          email: _auth.currentUser?.email ?? '',
          level: 'A1',
          progress: 0.0,
          completedLessons: 0,
          totalLessons: 100, //
          score: 0,
          dailyCompleted: 0,
          targetDaily: 5,
          dailyStreak: 0,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        );
        await firestore.collection('users').doc(userId).set(newUser.toJson());
        _updateLocalState(newUser);
      }
    } catch (e) {
      print('❌ Error loading user: $e');
    }
  }

  Future<void> updateProgress({
    required int newCompleted,
    required int newDailyCompleted,
    required int newTotal,
    required int newScore,
  }) async {
    if (userId.isEmpty) return;

    try {
      // Kiểm tra nếu đạt daily goal, tăng streak
      int newStreak = dailyStreak.value;
      if (newDailyCompleted >= targetDaily.value) {
        newStreak = dailyStreak.value + 1;
      }

      await firestore.collection('users').doc(userId).update({
        'completedLessons': newCompleted,
        'dailyCompleted': newDailyCompleted,
        'totalLessons': newTotal,
        'score': newScore,
        'dailyStreak': newStreak,
        'progress': (newCompleted / newTotal) * 100, // ⭐ Calculate progress %
        'updatedAt': FieldValue.serverTimestamp(),
      });

      //  Không cần update local - stream sẽ tự động update
    } catch (e) {
      print('❌ Error updating progress: $e');
    }
  }

  ///  UPDATED: Reset daily progress (gọi vào 00:00 mỗi ngày)
  Future<void> resetDailyProgress() async {
    if (userId.isEmpty) return;

    try {
      // Lấy data hiện tại
      final doc = await firestore.collection('users').doc(userId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final currentDaily = data['dailyCompleted'] ?? 0;
      final targetDaily = data['targetDaily'] ?? 5;
      final currentStreak = data['dailyStreak'] ?? 0;

      // Nếu không đạt goal hôm qua → reset streak
      int newStreak = currentStreak;
      if (currentDaily < targetDaily) {
        newStreak = 0;
        print('⚠️ Streak reset! Did not reach daily goal yesterday.');
      }

      // Reset daily completed
      await firestore.collection('users').doc(userId).update({
        'dailyCompleted': 0,
        'dailyStreak': newStreak,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('🔄 Daily progress reset. Streak: $newStreak');
    } catch (e) {
      print('❌ Error resetting daily progress: $e');
    }
  }

  ///  NEW: Manual refresh (pull-to-refresh)
  Future<void> refresh() async {
    await loadUserProgress();
  }

  Future<void> logout() async {
    await _auth.signOut();
    Get.offAllNamed('/login');
  }
}