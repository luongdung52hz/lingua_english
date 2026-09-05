import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lesson_model.dart';
import 'user_repository.dart';

class LessonRepository {
  LessonRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  String get userId => _auth.currentUser?.uid ?? '';

  // Load lessons theo level + skill + topic (stream cho real-time)
  Stream<List<LessonModel>> getLessonsStream(
    String level,
    String skill, {
    String? topic,
  }) {
    var query = _firestore
        .collection('lessons')
        .where('level', isEqualTo: level)
        .where('skill', isEqualTo: skill)
        .orderBy('difficulty')
        .limit(20);

    if (topic != null && topic.isNotEmpty) {
      query = query.where('topic', isEqualTo: topic);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => LessonModel.fromJson(doc.data(), doc.id))
          .toList(),
    );
  }

  // Đếm số bài tổng/đã học theo level + skill + topic
  Future<Map<String, int>> getProgressStats(
    String level,
    String skill, {
    String? topic,
  }) async {
    if (userId.isEmpty) return {'total': 0, 'completed': 0};

    var totalQuery = _firestore
        .collection('lessons')
        .where('level', isEqualTo: level)
        .where('skill', isEqualTo: skill);

    if (topic != null && topic.isNotEmpty) {
      totalQuery = totalQuery.where('topic', isEqualTo: topic);
    }

    final totalSnap = await totalQuery.count().get();
    final total = totalSnap.count ?? 0;

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

    final completedSnap = await completedQuery.count().get();
    final completed = completedSnap.count ?? 0;

    return {'total': total, 'completed': completed};
  }

  Future<int> getTotalLessonsInDatabase() async {
    final snap = await _firestore.collection('lessons').count().get();
    return snap.count ?? 0;
  }

  // Lấy danh sách topics unique theo level + skill
  Future<List<String>> getTopicsByLevelAndSkill(
    String level,
    String skill,
  ) async {
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
  Stream<List<LessonModel>> getLessonsByTopic(
    String level,
    String skill,
    String topic,
  ) {
    return _firestore
        .collection('lessons')
        .where('level', isEqualTo: level)
        .where('skill', isEqualTo: skill)
        .where('topic', isEqualTo: topic)
        .orderBy('difficulty')
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LessonModel.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<LessonModel?> getLessonById(String id) async {
    final doc = await _firestore.collection('lessons').doc(id).get();
    return doc.exists ? LessonModel.fromJson(doc.data()!, doc.id) : null;
  }

  String _requireUserId() {
    final uid = userId;
    if (uid.isEmpty) throw StateError('User not authenticated');
    return uid;
  }

  /// Reopening a completed lesson must not reset its completion flag or score.
  Future<void> startLesson(
    String lessonId,
    String level,
    String skill, {
    String? topic,
  }) async {
    final ref = _firestore
        .collection('users')
        .doc(_requireUserId())
        .collection('user_progress')
        .doc(lessonId);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(ref);
      transaction.set(ref, {
        'lessonId': lessonId,
        'level': level,
        'skill': skill,
        if (topic != null) 'topic': topic,
        if (!doc.exists) ...{
          'completed': false,
          'score': 0,
          'timeSpent': 0,
          'startedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    });
  }

  /// Lesson completion and dashboard counters commit together.
  Future<void> completeLesson(String lessonId, int score, int timeSpent) async {
    final userRef = _firestore.collection('users').doc(_requireUserId());
    final progressRef = userRef.collection('user_progress').doc(lessonId);
    final lessonRef = _firestore.collection('lessons').doc(lessonId);
    await _firestore.runTransaction((transaction) async {
      final user = await transaction.get(userRef);
      final progress = await transaction.get(progressRef);
      final lesson = await transaction.get(lessonRef);
      if (!user.exists || !lesson.exists)
        throw StateError('User or lesson not found');
      final next = UserRepository.progressFromJson(user.data()!).complete(
        firstCompletion: progress.data()?['completed'] != true,
        now: DateTime.now(),
      );
      transaction.set(progressRef, {
        'lessonId': lessonId,
        'level': lesson.data()!['level'],
        'skill': lesson.data()!['skill'],
        'topic': lesson.data()!['topic'],
        'completed': true,
        'score': score,
        'timeSpent': timeSpent,
        'completedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      transaction.update(userRef, UserRepository.progressToJson(next));
    });
  }
}
