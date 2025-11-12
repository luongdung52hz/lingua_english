// lib/data/models/quiz_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizAIModel {
  final String id;
  final List<String> participants; // [uid1, uid2]
  final List<QuizQuestion> questions; // Danh sách câu hỏi
  final String level; // Level của quiz (e.g., "A1")
  final Timestamp createdAt;
  final Map<String, int> scores; // {uid: score}
  final QuizStatus status; // pending, invited, ongoing, finished
  final String title; // Thêm: Tiêu đề quiz (e.g., "Duel Quiz Level A1")

  QuizAIModel({
    required this.id,
    required this.participants,
    required this.questions,
    required this.level,
    required this.createdAt,
    this.scores = const {},
    this.status = QuizStatus.pending,
    this.title = 'Duel Quiz', // Default title
  });

  factory QuizAIModel.fromJson(Map<String, dynamic> json) {
    return QuizAIModel(
      id: json['id'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      questions: (json['questions'] as List<dynamic>?)
          ?.map((q) => QuizQuestion.fromJson(q))
          .toList() ?? [],
      level: json['level'] ?? 'A1',
      createdAt: json['createdAt'] ?? Timestamp.now(),
      scores: Map<String, int>.from(json['scores'] ?? {}),
      title: json['title'] ?? 'Duel Quiz', // Parse title
      status: _parseStatus(json['status'] ?? 'pending'), // Parsing an toàn
    );
  }

  // Helper method cho enum parsing an toàn (tránh crash nếu status không khớp)
  static QuizStatus _parseStatus(String statusStr) {
    const statusMap = {
      'pending': QuizStatus.pending,
      'invited': QuizStatus.invited,
      'ongoing': QuizStatus.ongoing,
      'finished': QuizStatus.finished,
    };
    return statusMap[statusStr] ?? QuizStatus.pending;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'participants': participants,
    'questions': questions.map((q) => q.toJson()).toList(),
    'level': level,
    'createdAt': createdAt,
    'scores': scores,
    'status': status.toString().split('.').last,
    'title': title, // Serialize title
  };

  // Thêm: copyWith method để dễ update (e.g., thay đổi status/title)
  QuizAIModel copyWith({
    String? id,
    List<String>? participants,
    List<QuizQuestion>? questions,
    String? level,
    Timestamp? createdAt,
    Map<String, int>? scores,
    QuizStatus? status,
    String? title,
  }) {
    return QuizAIModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      questions: questions ?? this.questions,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      scores: scores ?? this.scores,
      status: status ?? this.status,
      title: title ?? this.title,
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options; // 4 lựa chọn A/B/C/D
  final String correctAnswer; // e.g., "A"

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer,
  };
}

enum QuizStatus { pending, invited, ongoing, finished } // Thêm 'invited' cho invite state