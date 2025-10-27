class WritingResult {
  final int score;
  final int grammarScore;
  final int vocabularyScore;
  final int structureScore;
  final int contentScore;
  final String feedback;
  final List<String> strengths;
  final List<String> improvements;
  final List<GrammarError> grammarErrors;
  final List<VocabularySuggestion> vocabularySuggestions;
  final int wordCount;
  final bool meetsRequirements;
  final bool hasError;
  final String? errorMessage;

  WritingResult({
    required this.score,
    required this.grammarScore,
    required this.vocabularyScore,
    required this.structureScore,
    required this.contentScore,
    required this.feedback,
    required this.strengths,
    required this.improvements,
    required this.grammarErrors,
    required this.vocabularySuggestions,
    required this.wordCount,
    required this.meetsRequirements,
    this.hasError = false,
    this.errorMessage,
  });

  factory WritingResult.fromJson(Map<String, dynamic> json) {
    return WritingResult(
      score: (json['score'] as num?)?.toInt() ?? 0,
      grammarScore: (json['grammar_score'] as num?)?.toInt() ?? 0,
      vocabularyScore: (json['vocabulary_score'] as num?)?.toInt() ?? 0,
      structureScore: (json['structure_score'] as num?)?.toInt() ?? 0,
      contentScore: (json['content_score'] as num?)?.toInt() ?? 0,
      feedback: json['feedback']?.toString() ?? '',
      strengths: _parseStringList(json['strengths']),
      improvements: _parseStringList(json['improvements']),
      grammarErrors: _parseGrammarErrors(json['grammar_errors']),
      vocabularySuggestions: _parseVocabularySuggestions(json['vocabulary_suggestions']),
      wordCount: (json['word_count'] as num?)?.toInt() ?? 0,
      meetsRequirements: json['meets_requirements'] == true,
    );
  }

  // Helper methods để xử lý list parsing an toàn
  static List<String> _parseStringList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.whereType<String>().toList();
    }
    return [];
  }

  static List<GrammarError> _parseGrammarErrors(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => GrammarError.fromJson(e))
          .toList();
    }
    return [];
  }

  static List<VocabularySuggestion> _parseVocabularySuggestions(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => VocabularySuggestion.fromJson(e))
          .toList();
    }
    return [];
  }

  factory WritingResult.error(String message) {
    return WritingResult(
      score: 0,
      grammarScore: 0,
      vocabularyScore: 0,
      structureScore: 0,
      contentScore: 0,
      feedback: message,
      strengths: [],
      improvements: [],
      grammarErrors: [],
      vocabularySuggestions: [],
      wordCount: 0,
      meetsRequirements: false,
      hasError: true,
      errorMessage: message,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'grammar_score': grammarScore,
      'vocabulary_score': vocabularyScore,
      'structure_score': structureScore,
      'content_score': contentScore,
      'feedback': feedback,
      'strengths': strengths,
      'improvements': improvements,
      'grammar_errors': grammarErrors.map((e) => e.toJson()).toList(),
      'vocabulary_suggestions':
      vocabularySuggestions.map((e) => e.toJson()).toList(),
      'word_count': wordCount,
      'meets_requirements': meetsRequirements,
    };
  }
}

class GrammarError {
  final String error;
  final String correction;
  final String explanation;

  GrammarError({
    required this.error,
    required this.correction,
    required this.explanation,
  });

  factory GrammarError.fromJson(Map<String, dynamic> json) {
    return GrammarError(
      error: json['error'] ?? '',
      correction: json['correction'] ?? '',
      explanation: json['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'correction': correction,
      'explanation': explanation,
    };
  }
}

class VocabularySuggestion {
  final String word;
  final String better;
  final String context;

  VocabularySuggestion({
    required this.word,
    required this.better,
    required this.context,
  });

  factory VocabularySuggestion.fromJson(Map<String, dynamic> json) {
    return VocabularySuggestion(
      word: json['word'] ?? '',
      better: json['better'] ?? '',
      context: json['context'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'better': better,
      'context': context,
    };
  }
}