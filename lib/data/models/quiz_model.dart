import 'package:learn_english/data/models/question_model.dart';

class QuizModel {
  final String id;
  final String title;
  final String description;
  final List<QuestionModel> questions;
  final DateTime createdAt;
  final String createdBy;
  final String? pdfFileName;
  final int totalQuestions;
  final QuizStatus status;

  QuizModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.questions,
    required this.createdAt,
    this.createdBy = '',
    this.pdfFileName,
    required this.totalQuestions,
    this.status = QuizStatus.draft,
  });

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'pdfFileName': pdfFileName,
      'totalQuestions': totalQuestions,
      'status': status.name,
    };
  }

  // Create from Firebase JSON
  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled Quiz',
      description: json['description'] ?? '',
      questions: (json['questions'] as List?)
          ?.map((q) => QuestionModel.fromJson(q))
          .toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      createdBy: json['createdBy'] ?? '',
      pdfFileName: json['pdfFileName'],
      totalQuestions: json['totalQuestions'] ?? 0,
      status: QuizStatus.values.firstWhere(
            (s) => s.name == json['status'],
        orElse: () => QuizStatus.draft,
      ),
    );
  }

  // Calculate completion percentage
  double get completionPercentage {
    if (questions.isEmpty) return 0;
    final completeQuestions = questions.where((q) => q.isComplete).length;
    return (completeQuestions / questions.length) * 100;
  }

  // Check if all questions have answers
  bool get isComplete => questions.every((q) => q.isComplete);

  // Count incomplete questions
  int get incompleteCount => questions.where((q) => !q.isComplete).length;

  QuizModel copyWith({
    String? id,
    String? title,
    String? description,
    List<QuestionModel>? questions,
    DateTime? createdAt,
    String? createdBy,
    String? pdfFileName,
    int? totalQuestions,
    QuizStatus? status,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      pdfFileName: pdfFileName ?? this.pdfFileName,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      status: status ?? this.status,
    );
  }
}

// Quiz status enum
enum QuizStatus {
  draft,      // Đang soạn thảo
  processing, // Đang xử lý AI
  published,  // Đã xuất bản
  archived,   // Đã lưu trữ
}