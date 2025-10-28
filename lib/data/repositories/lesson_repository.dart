import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import '../models/lesson_model.dart';
import '../../data/models/user_progress.dart';

class LessonRepository {
  final FirebaseFirestore _firestore = GetIt.I<FirebaseFirestore>();
  final String userId = GetIt.I<FirebaseAuth>().currentUser?.uid ?? '';

  // Load lessons theo level + skill + topic (stream cho real-time)
  Stream<List<LessonModel>> getLessonsStream(String level, String skill, {String? topic}) {
    var query = _firestore
        .collection('lessons')
        .where('level', isEqualTo: level)
        .where('skill', isEqualTo: skill)
        .orderBy('difficulty')
        .limit(20);

    if (topic != null && topic.isNotEmpty) {
      query = query.where('topic', isEqualTo: topic);
    }

    return query.snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => LessonModel.fromJson(doc.data(), doc.id))
        .toList());
  }

  // Đếm số bài tổng/đã học theo level + skill + topic
  Future<Map<String, int>> getProgressStats(String level, String skill, {String? topic}) async {
    if (userId.isEmpty) return {'total': 0, 'completed': 0};

    var totalQuery = _firestore
        .collection('lessons')
        .where('level', isEqualTo: level)
        .where('skill', isEqualTo: skill);

    if (topic != null && topic.isNotEmpty) {
      totalQuery = totalQuery.where('topic', isEqualTo: topic);
    }

    final totalSnap = await totalQuery.get();
    final total = totalSnap.docs.length;

    var completedQuery = _firestore
        .collection('users')
        .doc(userId)
        .collection('user_progress')
        .where('level', isEqualTo: level)
        .where('skill', isEqualTo: skill)
        .where('completed', isEqualTo: true);

    if (topic != null && topic.isNotEmpty) {
      completedQuery = completedQuery.where('topic', isEqualTo: topic);
    }

    final completedSnap = await completedQuery.get();
    final completed = completedSnap.docs.length;

    return {'total': total, 'completed': completed};
  }

  Future<int> getTotalLessonsInDatabase() async {
    final snap = await _firestore.collection('lessons').get();
    return snap.docs.length;
  }

  // Lấy danh sách topics unique theo level + skill
  Future<List<String>> getTopicsByLevelAndSkill(String level, String skill) async {
    final snap = await _firestore
        .collection('lessons')
        .where('level', isEqualTo: level)
        .where('skill', isEqualTo: skill)
        .get();

    final topics = snap.docs
        .map((doc) => doc.data()['topic'] as String?)
        .where((topic) => topic != null && topic.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    return topics;
  }

  // Load lessons theo level + skill + topic
  Stream<List<LessonModel>> getLessonsByTopic(String level, String skill, String topic) {
    return _firestore
        .collection('lessons')
        .where('level', isEqualTo: level)
        .where('skill', isEqualTo: skill)
        .where('topic', isEqualTo: topic)
        .orderBy('difficulty')
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => LessonModel.fromJson(doc.data(), doc.id))
        .toList());
  }

  // Start lesson
  Future<void> startLesson(String lessonId, String level, String skill, {String? topic}) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('user_progress')
        .doc(lessonId)
        .set({
      'lessonId': lessonId,
      'completed': false,
      'score': 0,
      'timeSpent': 0,
      'level': level,
      'skill': skill,
      if (topic != null) 'topic': topic, // Thêm topic nếu có
      'startedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> completeLesson(String lessonId, int score, int timeSpent) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('user_progress')
        .doc(lessonId)
        .update({
      'completed': true,
      'score': score,
      'timeSpent': timeSpent,
      'completedAt': FieldValue.serverTimestamp(),
    });

    print('Lesson progress saved: $lessonId (score: $score)');
  }

  Future<void> setDefaultUserLevel() async {
    if (userId.isEmpty) return;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(userId).set({
          'uid': userId,
          'currentLevel': 'A1',
          'completedLessons': 0,
          'totalLessons': 100,
          'dailyCompleted': 0,
          'targetDaily': 5,
          'dailyStreak': 0,
          'score': 0,
          'progress': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print(' [LessonRepository] Created new user with defaults');
      } else {
        print(' [LessonRepository] User exists, preserving progress');
      }
    } catch (e) {
      print(' [LessonRepository.setDefaultUserLevel] Error: $e');
    }
  }
}