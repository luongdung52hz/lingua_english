class SpeakingResult {
  final int score;
  final int pronunciationScore;
  final int fluencyScore;
  final int accuracyScore;
  final String feedback;
  final List<String> strengths;
  final List<String> improvements;
  final List<String> detectedWords;
  final List<String> missingWords;
  final bool hasError;
  final String? errorMessage;

  SpeakingResult({
    required this.score,
    required this.pronunciationScore,
    required this.fluencyScore,
    required this.accuracyScore,
    required this.feedback,
    required this.strengths,
    required this.improvements,
    required this.detectedWords,
    required this.missingWords,
    this.hasError = false,
    this.errorMessage,
  });

  factory SpeakingResult.fromJson(Map<String, dynamic> json) {
    return SpeakingResult(
      score: json['score'] ?? 0,
      pronunciationScore: json['pronunciation_score'] ?? 0,
      fluencyScore: json['fluency_score'] ?? 0,
      accuracyScore: json['accuracy_score'] ?? 0,
      feedback: json['feedback'] ?? '',
      strengths: List<String>.from(json['strengths'] ?? []),
      improvements: List<String>.from(json['improvements'] ?? []),
      detectedWords: List<String>.from(json['detected_words'] ?? []),
      missingWords: List<String>.from(json['missing_words'] ?? []),
    );
  }

  factory SpeakingResult.error(String message) {
    return SpeakingResult(
      score: 0,
      pronunciationScore: 0,
      fluencyScore: 0,
      accuracyScore: 0,
      feedback: message,
      strengths: [],
      improvements: [],
      detectedWords: [],
      missingWords: [],
      hasError: true,
      errorMessage: message,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'pronunciation_score': pronunciationScore,
      'fluency_score': fluencyScore,
      'accuracy_score': accuracyScore,
      'feedback': feedback,
      'strengths': strengths,
      'improvements': improvements,
      'detected_words': detectedWords,
      'missing_words': missingWords,
    };
  }
}