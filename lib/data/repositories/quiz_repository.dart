
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_model.dart';

class QuizRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'quizzes';

  /// Save quiz to Firebase
  Future<String> saveQuiz(QuizModel quiz) async {
    try {
      final docRef = _firestore.collection(_collection).doc(quiz.id);
      await docRef.set(quiz.toJson());
      return quiz.id;
    } catch (e) {
      throw Exception('Lỗi lưu quiz: $e');
    }
  }

  /// Get quiz by ID
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

  /// Get all quizzes
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

  /// Get quizzes by status
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

  /// Update quiz
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

  /// Delete quiz
  Future<void> deleteQuiz(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Lỗi xóa quiz: $e');
    }
  }

  /// Search quizzes by title
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

  /// Get quiz count
  Future<int?> getQuizCount() async {
    try {
      final snapshot = await _firestore.collection(_collection).count().get();
      return snapshot.count;
    } catch (e) {
      return 0;
    }
  }
}