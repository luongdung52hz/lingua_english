import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../models/question_model.dart';
import 'dart:convert';

class AIQuizService {
  final GenerativeModel _model;

  AIQuizService({required String apiKey})
      : _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: apiKey,
    generationConfig: GenerationConfig(
      temperature: 0.3,
      topK: 1,
      topP: 1,
      maxOutputTokens: 2048,
    ),
  );

  /// Fill missing correct answers for questions
  Future<List<QuestionModel>> fillMissingAnswers(
      List<QuestionModel> questions,
      ) async {
    final updatedQuestions = <QuestionModel>[];

    for (final question in questions) {
      if (question.isComplete) {
        updatedQuestions.add(question);
      } else {
        try {
          final answer = await _predictAnswer(question);
          updatedQuestions.add(question.copyWith(correctAnswer: answer));
        } catch (e) {
          print('⚠️ Lỗi AI cho câu "${question.question}": $e');
          updatedQuestions.add(question);
        }
      }
    }

    return updatedQuestions;
  }

  /// Predict correct answer for a single question
  Future<String> _predictAnswer(QuestionModel question) async {
    final prompt = _buildAnswerPredictionPrompt(question);

    final response = await _model.generateContent([Content.text(prompt)]);
    final answer = response.text?.trim() ?? '';

    // Validate answer is in options
    if (question.options.contains(answer)) {
      return answer;
    }

    // Try to find matching option
    for (final option in question.options) {
      if (option.toLowerCase().contains(answer.toLowerCase()) ||
          answer.toLowerCase().contains(option.toLowerCase())) {
        return option;
      }
    }

    // Return first option as fallback
    return question.options.first;
  }

  String _buildAnswerPredictionPrompt(QuestionModel question) {
    return '''
Bạn là trợ lý AI chuyên về giáo dục. Nhiệm vụ của bạn là xác định đáp án ĐÚNG NHẤT cho câu hỏi dưới đây.

**Câu hỏi:**
${question.question}

**Các đáp án:**
${question.options.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}

**Yêu cầu:**
- Phân tích kỹ câu hỏi và tất cả các đáp án
- Chọn đáp án CHÍNH XÁC nhất dựa trên kiến thức chuyên môn
- CHỈ trả về NỘI DUNG CHÍNH XÁC của đáp án đúng (không thêm số thứ tự, không giải thích)
- Đáp án phải GIỐNG HỆT với một trong các đáp án được cung cấp

**Ví dụ:**
Nếu đáp án đúng là "2. Java", chỉ trả về: Java

**Đáp án đúng:**''';
  }

  /// Generate explanation for a question
  Future<String> generateExplanation(QuestionModel question) async {
    final prompt = '''
Hãy giải thích tại sao đáp án "${question.correctAnswer}" là đúng cho câu hỏi sau:

**Câu hỏi:** ${question.question}

**Các đáp án:**
${question.options.asMap().entries.map((e) => '${String.fromCharCode(65 + e.key)}. ${e.value}').join('\n')}

**Đáp án đúng:** ${question.correctAnswer}

Hãy giải thích ngắn gọn, dễ hiểu (2-3 câu):''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Improve question quality
  Future<QuestionModel> improveQuestion(QuestionModel question) async {
    final prompt = '''
Cải thiện chất lượng câu hỏi sau để rõ ràng và chính xác hơn:

**Câu hỏi gốc:** ${question.question}
**Các đáp án:** ${question.options.join(', ')}

Hãy:
1. Viết lại câu hỏi rõ ràng, súc tích hơn
2. Đảm bảo câu hỏi không mơ hồ
3. Giữ nguyên ý nghĩa

Chỉ trả về câu hỏi đã cải thiện (không thêm gì khác):''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final improvedQuestion = response.text?.trim() ?? question.question;

      return question.copyWith(question: improvedQuestion);
    } catch (e) {
      return question;
    }
  }

  /// Generate quiz title from content
  Future<String> generateQuizTitle(List<QuestionModel> questions) async {
    if (questions.isEmpty) return 'Quiz không có tiêu đề';

    final sampleQuestions = questions.take(3).map((q) => q.question).join('\n');

    final prompt = '''
Dựa trên các câu hỏi sau, hãy đặt tên ngắn gọn (tối đa 6 từ) cho bộ quiz:

$sampleQuestions

Chỉ trả về tiêu đề (ví dụ: "Quiz Java Cơ Bản", "Kiến thức Lập trình C++"):''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'Quiz không có tiêu đề';
    } catch (e) {
      return 'Quiz không có tiêu đề';
    }
  }

  /// Batch process questions (more efficient)
  Future<List<QuestionModel>> fillMissingAnswersBatch(
      List<QuestionModel> questions,
      ) async {
    final incompleteQuestions = questions.where((q) => !q.isComplete).toList();

    if (incompleteQuestions.isEmpty) return questions;

    final prompt = _buildBatchPrompt(incompleteQuestions);

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final answersJson = response.text?.trim() ?? '[]';

      final answers = jsonDecode(answersJson) as List;

      final updatedQuestions = <QuestionModel>[...questions];

      for (int i = 0; i < incompleteQuestions.length; i++) {
        final originalIndex = questions.indexOf(incompleteQuestions[i]);
        if (i < answers.length) {
          updatedQuestions[originalIndex] = incompleteQuestions[i].copyWith(
            correctAnswer: answers[i].toString(),
          );
        }
      }

      return updatedQuestions;
    } catch (e) {
      print('⚠️ Lỗi batch AI, fallback về xử lý từng câu: $e');
      return fillMissingAnswers(questions);
    }
  }

  String _buildBatchPrompt(List<QuestionModel> questions) {
    final questionsText = questions.asMap().entries.map((entry) {
      final i = entry.key;
      final q = entry.value;
      return '''
Câu ${i + 1}:
${q.question}
Các đáp án: ${q.options.join(' | ')}''';
    }).join('\n\n');

    return '''
Hãy xác định đáp án đúng cho từng câu hỏi dưới đây. Trả về mảng JSON chứa các đáp án.

$questionsText

Trả về format JSON array:
["đáp án 1", "đáp án 2", "đáp án 3"]

CHỈ trả về JSON array, không giải thích gì thêm.''';
  }
}