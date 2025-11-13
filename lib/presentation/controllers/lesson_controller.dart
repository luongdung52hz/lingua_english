import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart'; // Import GetIt
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../data/models/lesson_model.dart';

class LearnController extends GetxController {
  final LessonRepository _repo = GetIt.I<LessonRepository>();
  final FirebaseFirestore _firestore = GetIt.I<FirebaseFirestore>();

  // Reactive
  final RxList<LessonModel> lessons = <LessonModel>[].obs;
  final RxInt totalLessons = 0.obs;
  final RxInt completedLessons = 0.obs;
  final RxString currentLevel = 'A1'.obs;
  final RxString currentSkill = 'listening'.obs;
  final Rx<LessonModel?> currentLesson = Rx<LessonModel?>(null);
  final RxList<String> topics = <String>[].obs; // ⭐ Thêm RxList cho topics (dynamic theo level/skill)
  final RxString currentTopic = ''.obs; // Thêm dòng này

  final List<String> levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']; // CEFR
  final List<String> skills = ['listening', 'speaking', 'reading', 'writing'];

  @override
  void onInit() {
    super.onInit();
    _repo.setDefaultUserLevel();
    loadLessons(currentLevel.value, currentSkill.value); // Load default và topics
  }

  Future<void> loadLessons(String level, String skill) async {
    currentLevel.value = level;
    currentSkill.value = skill;
    currentTopic.value = ''; // ⭐ Sửa: Set currentTopic = '' (default empty, không undefined 'topic')

    // Load lessons stream
    _repo.getLessonsStream(level, skill).listen((data) {
      lessons.value = data;
      totalLessons.value = data.length;
    });

    // Load stats
    final stats = await _repo.getProgressStats(level, skill);
    completedLessons.value = stats['completed'] ?? 0;

    // ⭐ Load topics unique từ repo (hoặc extract từ lessons)
    await _loadTopics(level, skill);
  }

  /// ⭐ NEW: Load topics unique theo level + skill
  Future<void> _loadTopics(String level, String skill) async {
    try {
      // Gọi repo nếu có method getTopicsByLevelAndSkill
      final topicsList = await _repo.getTopicsByLevelAndSkill(level, skill);
      topics.value = topicsList;
    } catch (e) {
      print('Error loading topics: $e');
      // Fallback: Extract from current lessons
      final uniqueTopics = lessons.map((l) => l.topic ?? '').toSet().toList();
      topics.value = uniqueTopics;
    }
  }

  Future<void> loadLessonsByTopic(String level, String skill, String? topic) async { // Add ? for null 'All'
    currentLevel.value = level;
    currentSkill.value = skill;
    // Remove: currentTopic.value = topic; // Widget handles

    // Branch: Handle null/empty topic as "All" (full stream, no filter)
    Stream<List<LessonModel>> lessonsStream;
    if (topic == null || topic.isEmpty) {
      lessonsStream = _repo.getLessonsStream(level, skill);
    } else {
      lessonsStream = _repo.getLessonsByTopic(level, skill, topic);
    }

    // Load lessons stream
    lessonsStream.listen((data) {
      lessons.value = data;
      totalLessons.value = data.length;
    });

    final stats = await _repo.getProgressStats(level, skill, topic: topic);
    completedLessons.value = stats['completed'] ?? 0;
  }

  Future<void> startLesson(LessonModel lesson) async {
    await _repo.startLesson(lesson.id, lesson.level, lesson.skill, topic: lesson.topic); // Thêm topic nếu có
  }

  Future<void> completeLesson(LessonModel lesson, int score, int timeSpent) async {
    try {
      final isFirstCompletion = await _isFirstCompletion(lesson.id);

      await _repo.completeLesson(lesson.id, score, timeSpent);

      await _updateProgress(isFirstCompletion);

      loadLessons(lesson.level, lesson.skill); // Refresh
    } catch (e) {
      print('❌ Error completing lesson: $e');
      rethrow;
    }
  }

  Future<bool> _isFirstCompletion(String lessonId) async {
    final userId = GetIt.I<FirebaseAuth>().currentUser?.uid ?? ''; // Sử dụng GetIt cho userId
    if (userId.isEmpty) return true;

    try {
      final progressDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_progress')
          .doc(lessonId)
          .get();

      if (!progressDoc.exists) return true;

      final data = progressDoc.data();
      final wasCompleted = data?['completed'] == true;

      return !wasCompleted;
    } catch (e) {
      print('⚠️ Error checking completion status: $e');
      return true; // Default first time
    }
  }

  Future<void> _updateProgress(bool isFirstCompletion) async {
    final userId = GetIt.I<FirebaseAuth>().currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final currentCompleted = data['completedLessons'] ?? 0;
      final currentDaily = data['dailyCompleted'] ?? 0;
      final targetDaily = data['targetDaily'] ?? 5;
      final currentStreak = data['dailyStreak'] ?? 0;

      final newCompleted = isFirstCompletion
          ? currentCompleted + 1
          : currentCompleted;

      final newDaily = currentDaily + 1;

      int newStreak = currentStreak;
      if (newDaily == targetDaily) {
        newStreak = currentStreak + 1;
        print('🔥 Daily goal reached! Streak +1 → $newStreak days');
      }

      await _firestore.collection('users').doc(userId).update({
        'completedLessons': newCompleted,
        'dailyCompleted': newDaily,
        'dailyStreak': newStreak,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (isFirstCompletion) {
        print('✅ First completion! Total: $newCompleted | Daily: $newDaily/$targetDaily | Streak: $newStreak 🔥');
      } else {
        print('🔄 Re-complete! Total: $newCompleted (no change) | Daily: $newDaily/$targetDaily | Streak: $newStreak 🔥');
      }
    } catch (e) {
      print('⚠️ Error updating progress: $e');
    }
  }

  Future<LessonModel?> loadLessonById(String lessonId) async {
    final snap = await _firestore.collection('lessons').doc(lessonId).get();
    if (snap.exists) {
      currentLesson.value = LessonModel.fromJson(snap.data()!, snap.id);
      return currentLesson.value;
    }
    return null;
  }

  Future<void> startLessonById(String lessonId) async {
    final lesson = await loadLessonById(lessonId);
    if (lesson != null) {
      await startLesson(lesson);
    }
  }

  void changeLevel(String level) {
    loadLessons(level, currentSkill.value);
  }

  void changeSkill(String skill) {
    loadLessons(currentLevel.value, skill);
  }
}