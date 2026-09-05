import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/progress/study_progress.dart';
import '../models/user_model.dart';

class UserRepository {
  UserRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  String get userId => _auth.currentUser?.uid ?? '';

  Future<UserModel?> getUserByUid(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists ? UserModel.fromJson({...doc.data()!, 'uid': uid}) : null;
  }

  Future<UserModel?> loadUser() async {
    final uid = userId;
    return uid.isEmpty ? null : getUserByUid(uid);
  }

  Stream<UserModel?> watchUser() {
    final uid = userId;
    if (uid.isEmpty) return Stream.value(null);
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map(
          (doc) => doc.exists
              ? UserModel.fromJson({...doc.data()!, 'uid': uid})
              : null,
        );
  }

  Future<bool> isAdmin(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['role'] == 'admin' || doc.data()?['isAdmin'] == true;
  }

  Future<String?> emailForUsername(String username) async {
    final result = await _firestore
        .collection('users')
        .where('name', isEqualTo: username.trim())
        .limit(1)
        .get();
    return result.docs.isEmpty
        ? null
        : result.docs.first.data()['email'] as String?;
  }

  /// Idempotent profile creation; existing learning data is never overwritten.
  Future<void> ensureProfile({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final ref = _firestore.collection('users').doc(user.uid);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(ref);
      if (!doc.exists) {
        transaction.set(
          ref,
          UserModel(
            uid: user.uid,
            name: name ?? user.displayName ?? 'User',
            email: email ?? user.email ?? '',
            phone: phone ?? '',
            level: 'A1',
            progress: 0,
            completedLessons: 0,
            totalLessons: 0,
            score: 0,
            dailyCompleted: 0,
            targetDaily: 5,
            dailyStreak: 0,
            createdAt: Timestamp.now(),
            updatedAt: Timestamp.now(),
          ).toJson(),
        );
      }
      transaction.set(ref, {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> prepareDashboard() async {
    await ensureProfile();
    final uid = userId;
    if (uid.isEmpty) return;
    // Count on the server instead of downloading every lesson document.
    final total =
        (await _firestore.collection('lessons').count().get()).count ?? 0;
    if (userId != uid) return;
    final ref = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(ref);
      if (!doc.exists) return;
      final data = doc.data()!;
      final progress = progressFromJson({
        ...data,
        'totalLessons': total,
      }).forDay(DateTime.now());
      transaction.update(ref, progressToJson(progress));
    });
  }

  static StudyProgress progressFromJson(Map<String, dynamic> data) =>
      StudyProgress(
        completed: (data['completedLessons'] as num?)?.toInt() ?? 0,
        daily: (data['dailyCompleted'] as num?)?.toInt() ?? 0,
        total: (data['totalLessons'] as num?)?.toInt() ?? 0,
        target: (data['targetDaily'] as num?)?.toInt() ?? 5,
        streak: (data['dailyStreak'] as num?)?.toInt() ?? 0,
        lastReset: (data['lastResetDate'] as Timestamp?)?.toDate(),
      );

  static Map<String, dynamic> progressToJson(StudyProgress value) => {
    'completedLessons': value.completed,
    'dailyCompleted': value.daily,
    'totalLessons': value.total,
    'dailyStreak': value.streak,
    'progress': value.percent,
    if (value.lastReset != null)
      'lastResetDate': Timestamp.fromDate(value.lastReset!),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
