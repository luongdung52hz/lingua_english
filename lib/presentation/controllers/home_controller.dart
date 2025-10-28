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

  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _userSubscription?.cancel();
    super.onClose();
  }

  Future<void> _initialize() async {
    await checkAndResetDaily();
    await syncTotalLessons();
    await loadUserProgress();
    _listenToUserChanges();
  }

  Future<void> syncTotalLessons() async {
    if (userId.isEmpty) return;

    try {
      final lessonsSnap = await firestore.collection('lessons').get();
      final actualTotal = lessonsSnap.docs.length;

      final userDoc = await firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final currentTotal = userDoc.data()?['totalLessons'] ?? 0;

      if (currentTotal != actualTotal) {
        final currentCompleted = userDoc.data()?['completedLessons'] ?? 0;
        final newProgress = actualTotal > 0 ? (currentCompleted / actualTotal) * 100 : 0.0;

        await firestore.collection('users').doc(userId).update({
          'totalLessons': actualTotal,
          'progress': newProgress,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('Total lessons synced: $actualTotal');
      }
    } catch (e) {
      print('Error syncing total lessons: $e');
    }
  }

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
      print('Error listening to user changes: $error');
    });
  }

  void _updateLocalState(UserModel user) {
    progressPercent.value = user.progress;
    completedLessons.value = user.completedLessons;
    totalLessons.value = user.totalLessons;
    score.value = user.score;
    dailyCompleted.value = user.dailyCompleted;
    targetDaily.value = user.targetDaily;
    dailyStreak.value = user.dailyStreak;
    userName.value = user.name;
  }

  Future<void> checkAndResetDaily() async {
    if (userId.isEmpty) return;

    try {
      final doc = await firestore.collection('users').doc(userId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final lastResetDate = data['lastResetDate'] as Timestamp?;
      final today = Timestamp.now();

      if (lastResetDate == null || !_isSameDay(lastResetDate.toDate(), today.toDate())) {
        await _resetDailyProgress();
        await firestore.collection('users').doc(userId).update({
          'lastResetDate': today,
        });
      }
    } catch (e) {
      print('Error checking daily reset: $e');
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> loadUserProgress() async {
    if (userId.isEmpty) return;

    try {
      final doc = await firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final user = UserModel.fromJson(doc.data()!);
        _updateLocalState(user);
      } else {
        await _createNewUser();
      }
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  Future<void> _createNewUser() async {
    final lessonsSnap = await firestore.collection('lessons').get();
    final actualTotal = lessonsSnap.docs.length;

    final newUser = UserModel(
      uid: userId,
      name: _auth.currentUser?.displayName ?? 'User',
      email: _auth.currentUser?.email ?? '',
      level: 'A1',
      progress: 0.0,
      completedLessons: 0,
      totalLessons: actualTotal,
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

  Future<void> updateProgress({
    required int newCompleted,
    required int newDailyCompleted,
    required int newTotal,
    required int newScore,
  }) async {
    if (userId.isEmpty) return;

    try {
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
        'progress': (newCompleted / newTotal) * 100,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating progress: $e');
    }
  }

  Future<void> _resetDailyProgress() async {
    if (userId.isEmpty) return;

    try {
      final doc = await firestore.collection('users').doc(userId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final currentDaily = data['dailyCompleted'] ?? 0;
      final targetDaily = data['targetDaily'] ?? 5;
      final currentStreak = data['dailyStreak'] ?? 0;

      int newStreak = currentStreak;
      if (currentDaily < targetDaily) {
        newStreak = 0;
      }

      await firestore.collection('users').doc(userId).update({
        'dailyCompleted': 0,
        'dailyStreak': newStreak,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error resetting daily progress: $e');
    }
  }

  Future<void> refresh() async {
    await syncTotalLessons();
    await loadUserProgress();
  }

  Future<void> logout() async {
    await _auth.signOut();
    Get.offAllNamed('/login');
  }
}