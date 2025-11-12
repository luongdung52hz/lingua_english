// lib/services/quiz_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../models/quiz_ai_model.dart';
import '../../models/quiz_model.dart' hide QuizStatus; // Sửa: Import từ quiz_model.dart (unify với QuizAIModel)

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String xaiApiUrl = 'https://api.x.ai/v1/chat/completions'; // Redirect to https://x.ai/api for full docs
  static const String xaiApiKey = 'YOUR_XAI_API_KEY'; // Lấy từ xAI dashboard (sử dụng env vars trong production)

  // Tạo quiz bằng AI (sửa: Set status invited cho duel, thêm title)
  Future<QuizAIModel> createAIQuiz(String level, String creatorUid, String opponentUid) async {
    // Gọi xAI API để generate questions
    final prompt = 'Generate 10 English multiple-choice quiz questions for level $level. Each question has 4 options (A,B,C,D), and provide the correct answer as "A/B/C/D". Format as JSON array of objects: {"question": "...", "options": ["A. ...", "B. ..."], "correctAnswer": "A"}';

    final response = await http.post(
      Uri.parse(xaiApiUrl),
      headers: {
        'Authorization': 'Bearer $xaiApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'grok-beta', // Hoặc model phù hợp (check docs tại https://x.ai/api)
        'messages': [{'role': 'user', 'content': prompt}],
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to generate quiz: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'];
    // Parse JSON từ content (thêm try-catch cho robust parsing)
    List<dynamic> questionsJson;
    try {
      questionsJson = jsonDecode(content);
    } catch (e) {
      throw Exception('Invalid JSON from AI: $e. Content: $content');
    }
    final questions = questionsJson.map<QuizQuestion>((q) => QuizQuestion.fromJson(q)).toList();

    // Tạo QuizModel và lưu Firestore (sửa: status invited, thêm title)
    final quizId = _firestore.collection('quizzes').doc().id;
    final title = 'Duel Quiz Level $level';
    final quiz = QuizAIModel(
      id: quizId,
      participants: [creatorUid, opponentUid],
      questions: questions,
      level: level,
      createdAt: Timestamp.now(),
      status: QuizStatus.invited, // Sửa: invited cho duel invite
      title: title,
    );

    await _firestore.collection('quizzes').doc(quizId).set(quiz.toJson());

    // Gửi invite (sửa: Thêm creator vào participants nếu cần, nhưng đã có)
    await _firestore.collection('users').doc(opponentUid).update({
      'quizInvites': FieldValue.arrayUnion([quizId]),
    });

    return quiz;
  }

  // Update score khi user trả lời (sửa: Hoàn thiện với validation, track answers, check finished)
  Future<void> submitAnswer(String quizId, String uid, int questionIndex, String answer) async {
    final quizRef = _firestore.collection('quizzes').doc(quizId);
    final quizSnap = await quizRef.get();
    if (!quizSnap.exists) throw Exception('Quiz not found');

    final quizData = quizSnap.data()!;
    final quiz = QuizAIModel.fromJson(quizData);

    // Validate: Quiz ongoing, chưa answer index này
    if (quiz.status != QuizStatus.ongoing) throw Exception('Quiz not active');
    final userAnswers = Map<String, dynamic>.from(quizData['answers']?[uid] ?? <String, dynamic>{});
    if (userAnswers[questionIndex.toString()] != null) throw Exception('Already answered this question');

    final question = quiz.questions[questionIndex];
    final isCorrect = answer == question.correctAnswer;
    final newScore = (quiz.scores[uid] ?? 0) + (isCorrect ? 1 : 0);

    // Update score và answers (sử dụng Map cho answers: {uid: {index: answer}})
    final updates = <String, dynamic>{
      'scores.$uid': newScore,
      'answers.$uid.$questionIndex': answer,
    };

    await quizRef.update(updates);

    // Kiểm tra finished nếu cả 2 hoàn thành (sửa: Logic đầy đủ)
    final totalQuestions = quiz.questions.length;
    final userAnsweredCount = (userAnswers.length + 1); // +1 cho current answer
    if (userAnsweredCount >= totalQuestions) {
      final otherUid = quiz.participants.firstWhere((u) => u != uid);
      final otherAnswers = Map<String, dynamic>.from(quizData['answers']?[otherUid] ?? <String, dynamic>{});
      final otherAnsweredCount = otherAnswers.length;
      if (otherAnsweredCount >= totalQuestions) {
        await quizRef.update({'status': 'finished'});
      }
    }
  }

  // Thêm: Accept quiz invite (update status ongoing, xóa invite) - Sửa: Dùng arrayRemove thay FieldPath
  Future<void> acceptQuiz(String quizId, String uid) async {
    final quizRef = _firestore.collection('quizzes').doc(quizId);
    final userRef = _firestore.collection('users').doc(uid);

    // Transaction để atomic update
    await _firestore.runTransaction((transaction) async {
      final quizSnap = await transaction.get(quizRef);
      if (!quizSnap.exists || QuizAIModel.fromJson(quizSnap.data()!).status != QuizStatus.invited) {
        throw Exception('Invalid invite');
      }

      transaction.update(quizRef, {'status': 'ongoing'});
      transaction.update(userRef, {
        'quizInvites': FieldValue.arrayRemove([quizId]), // Sửa: arrayRemove cho xóa element khỏi array
      });
    });
  }

  // Stream quiz cho user
  Stream<QuizAIModel?> getQuizStream(String quizId) {
    return _firestore.collection('quizzes').doc(quizId).snapshots().map((doc) =>
    doc.exists ? QuizAIModel.fromJson(doc.data()!) : null);
  }

  // Thêm: Stream invites cho user
  Stream<List<String>> getUserQuizInvitesStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) =>
    List<String>.from(doc.data()?['quizInvites'] ?? []));
  }
}