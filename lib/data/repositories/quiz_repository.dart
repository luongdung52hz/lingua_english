
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_model.dart';

class QuizRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'quizzes';

  Future<String> saveQuiz(QuizModel quiz) async {
    try {
      final docRef = _firestore.collection(_collection).doc(quiz.id);
      await docRef.set(quiz.toJson());
      return quiz.id;
    } catch (e) {
      throw Exception('Lỗi lưu quiz: $e');
    }
  }

  Future<QuizModel?> getQuizById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();

      if (!doc.exists) return null;

      return QuizModel.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      throw Exception('Lỗi lấy quiz: $e');
    }
  }

  Future<List<QuizModel>> getAllQuizzes() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => QuizModel.fromJson({
        'id': doc.id,
        ...doc.data(),
      }))
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy danh sách quiz: $e');
    }
  }

  Future<List<QuizModel>> getQuizzesByStatus(QuizStatus status) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => QuizModel.fromJson({
        'id': doc.id,
        ...doc.data(),
      }))
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy quiz theo status: $e');
    }
  }

  Future<void> updateQuiz(QuizModel quiz) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(quiz.id)
          .update(quiz.toJson());
    } catch (e) {
      throw Exception('Lỗi cập nhật quiz: $e');
    }
  }

  Future<void> deleteQuiz(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Lỗi xóa quiz: $e');
    }
  }

  Future<List<QuizModel>> searchQuizzes(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return snapshot.docs
          .map((doc) => QuizModel.fromJson({
        'id': doc.id,
        ...doc.data(),
      }))
          .toList();
    } catch (e) {
      throw Exception('Lỗi tìm kiếm quiz: $e');
    }
  }

  Future<int?> getQuizCount() async {
    try {
      final snapshot = await _firestore.collection(_collection).count().get();
      return snapshot.count;
    } catch (e) {
      return 0;
    }
  }
}