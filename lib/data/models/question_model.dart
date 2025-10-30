class QuestionModel {
  final String id;
  final String question;
  final List<String> options;
  final String? correctAnswer;
  final String? explanation;

  QuestionModel({
    required this.id,
    required this.question,
    required this.options,
    this.correctAnswer,
    this.explanation,
  });

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
    };
  }

  // Create from Firebase JSON
  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'],
      explanation: json['explanation'],
    );
  }

  // Check if question is complete (has correct answer)
  bool get isComplete => correctAnswer != null && correctAnswer!.isNotEmpty;

  // Create a copy with updated fields
  QuestionModel copyWith({
    String? id,
    String? question,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
    );
  }
}