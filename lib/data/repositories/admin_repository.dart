import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_model.dart';

class AdminRepository {
  AdminRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;
  final FirebaseFirestore _firestore;
  Stream<List<LessonModel>> watchLessons() => _firestore
      .collection('lessons')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => LessonModel.fromJson(doc.data(), doc.id))
            .toList(),
      );
  Future<void> addLesson(LessonModel lesson) async {
    await _firestore.collection('lessons').add(lesson.toJson());
  }

  Future<void> updateLesson(String id, Map<String, dynamic> fields) =>
      _firestore.collection('lessons').doc(id).update(fields);
  Future<void> deleteLesson(String id) =>
      _firestore.collection('lessons').doc(id).delete();
}
