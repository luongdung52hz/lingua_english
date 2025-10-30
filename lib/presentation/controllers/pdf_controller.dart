import 'dart:io';
import 'package:get/get.dart';
import '../../data/datasources/remote/ai/ai_quiz_service.dart';
import '../../data/datasources/remote/pdf_service.dart';
import '../../data/datasources/remote/quiz_parser.dart';
import '../../data/models/quiz_model.dart';
import '../../data/models/question_model.dart';
import '../../data/repositories/quiz_repository.dart';

class PdfController extends GetxController {
  final PDFService _pdfService = PDFService();
  final QuizParser _quizParser = QuizParser();
  late final AIQuizService _aiService;
  final QuizRepository _quizRepository = QuizRepository();

  // State
  final isProcessing = false.obs;
  final processingStage = ''.obs;
  final progress = 0.0.obs;
  final errorMessage = ''.obs;

  // Results
  final extractedText = ''.obs;
  final parsedQuestions = <QuestionModel>[].obs;
  final currentQuiz = Rx<QuizModel?>(null);

  // ✅ ID generator thay uuid
  String _generateId() {
    return 'quiz_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  @override
  void onInit() {
    super.onInit();
    // Initialize AI service with your API key
    _aiService = AIQuizService(apiKey: 'YOUR_GEMINI_API_KEY');
  }

  /// Main function: Process PDF file and create quiz
  Future<void> processPdfFile(File file) async {
    try {
      isProcessing.value = true;
      errorMessage.value = '';
      progress.value = 0.0;

      // Stage 1: Extract text from PDF
      await _extractTextFromPdf(file);

      // Stage 2: Parse questions
      await _parseQuestions();

      // Stage 3: Fill missing answers with AI
      await _fillMissingAnswers();

      // Stage 4: Generate quiz metadata
      await _generateQuizMetadata(file);

      // Stage 5: Save to Firebase
      await _saveQuizToFirebase();

      // Success
      Get.snackbar(
        '🎉 Thành công',
        'Tạo quiz thành công với ${parsedQuestions.length} câu hỏi!',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar(
        '❌ Lỗi',
        'Không thể tạo quiz: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isProcessing.value = false;
      processingStage.value = '';
    }
  }

  /// Stage 1: Extract text from PDF
  Future<void> _extractTextFromPdf(File file) async {
    processingStage.value = '📄 Đang đọc file PDF...';
    progress.value = 0.2;

    try {
      extractedText.value = await _pdfService.extractText(file);

      if (extractedText.value.isEmpty) {
        throw Exception('File PDF không chứa văn bản có thể đọc được');
      }

      print('✅ Đã trích xuất ${extractedText.value.length} ký tự');
    } catch (e) {
      throw Exception('Lỗi đọc PDF: $e');
    }
  }

  /// Stage 2: Parse questions from text
  Future<void> _parseQuestions() async {
    processingStage.value = '🔍 Đang phân tích câu hỏi...';
    progress.value = 0.4;

    try {
      parsedQuestions.value = await _quizParser.parse(extractedText.value);

      if (parsedQuestions.isEmpty) {
        throw Exception('Không tìm thấy câu hỏi nào trong file PDF');
      }

      // Validate questions
      final errors = _quizParser.validateQuestions(parsedQuestions);
      if (errors.isNotEmpty) {
        print('⚠️ Cảnh báo:\n${errors.join('\n')}');
      }

      print('✅ Đã phân tích ${parsedQuestions.length} câu hỏi');

      // Count incomplete questions
      final incompleteCount = parsedQuestions.where((q) => !q.isComplete).length;
      if (incompleteCount > 0) {
        print('⚠️ Có $incompleteCount câu thiếu đáp án, sẽ dùng AI bổ sung');
      }
    } catch (e) {
      throw Exception('Lỗi phân tích câu hỏi: $e');
    }
  }

  /// Stage 3: Fill missing answers with AI
  Future<void> _fillMissingAnswers() async {
    final incompleteCount = parsedQuestions.where((q) => !q.isComplete).length;

    if (incompleteCount == 0) {
      print('✅ Tất cả câu hỏi đã có đáp án');
      progress.value = 0.7;
      return;
    }

    processingStage.value = '🤖 AI đang bổ sung $incompleteCount đáp án...';
    progress.value = 0.6;

    try {
      // Use batch processing for better performance
      parsedQuestions.value = await _aiService.fillMissingAnswersBatch(
        parsedQuestions,
      );

      // Verify all questions now have answers
      final stillIncomplete = parsedQuestions.where((q) => !q.isComplete).length;
      if (stillIncomplete > 0) {
        print('⚠️ Vẫn còn $stillIncomplete câu chưa có đáp án');
      } else {
        print('✅ AI đã bổ sung đủ đáp án cho tất cả câu hỏi');
      }

      progress.value = 0.7;
    } catch (e) {
      throw Exception('Lỗi AI bổ sung đáp án: $e');
    }
  }

  /// Stage 4: Generate quiz metadata
  Future<void> _generateQuizMetadata(File file) async {
    processingStage.value = '📝 Đang tạo thông tin quiz...';
    progress.value = 0.8;

    try {
      // Generate title from questions
      final title = await _aiService.generateQuizTitle(parsedQuestions);

      // Create quiz model
      currentQuiz.value = QuizModel(
        id: _generateId(), // ✅ Dùng hàm tự tạo
        title: title,
        description: 'Quiz được tạo từ file PDF',
        questions: parsedQuestions,
        createdAt: DateTime.now(),
        pdfFileName: file.path.split('/').last,
        totalQuestions: parsedQuestions.length,
        status: QuizStatus.draft,
      );

      print('✅ Đã tạo quiz: ${currentQuiz.value!.title}');
    } catch (e) {
      throw Exception('Lỗi tạo metadata: $e');
    }
  }

  /// Stage 5: Save quiz to Firebase
  Future<void> _saveQuizToFirebase() async {
    if (currentQuiz.value == null) {
      throw Exception('Quiz chưa được tạo');
    }

    processingStage.value = '☁️ Đang lưu lên Firebase...';
    progress.value = 0.9;

    try {
      final quizId = await _quizRepository.saveQuiz(currentQuiz.value!);

      // Update quiz with published status
      currentQuiz.value = currentQuiz.value!.copyWith(
        status: QuizStatus.published,
      );

      await _quizRepository.updateQuiz(currentQuiz.value!);

      print('✅ Đã lưu quiz với ID: $quizId');
      progress.value = 1.0;
    } catch (e) {
      throw Exception('Lỗi lưu Firebase: $e');
    }
  }

  /// Preview mode: Process without saving
  Future<QuizModel> previewPdfFile(File file) async {
    await _extractTextFromPdf(file);
    await _parseQuestions();

    return QuizModel(
      id: 'preview_${DateTime.now().millisecondsSinceEpoch}', // ✅ Thêm timestamp
      title: 'Preview Quiz',
      questions: parsedQuestions,
      createdAt: DateTime.now(),
      pdfFileName: file.path.split('/').last,
      totalQuestions: parsedQuestions.length,
      status: QuizStatus.draft,
    );
  }

  /// Edit question manually
  void updateQuestion(int index, QuestionModel updatedQuestion) {
    if (index >= 0 && index < parsedQuestions.length) {
      parsedQuestions[index] = updatedQuestion;
      parsedQuestions.refresh();
    }
  }

  /// Remove question
  void removeQuestion(int index) {
    if (index >= 0 && index < parsedQuestions.length) {
      parsedQuestions.removeAt(index);
    }
  }

  /// Clear all data
  void clear() {
    extractedText.value = '';
    parsedQuestions.clear();
    currentQuiz.value = null;
    errorMessage.value = '';
    progress.value = 0.0;
  }

  /// Get processing summary
  Map<String, dynamic> getProcessingSummary() {
    return {
      'totalQuestions': parsedQuestions.length,
      'completeQuestions': parsedQuestions.where((q) => q.isComplete).length,
      'incompleteQuestions': parsedQuestions.where((q) => !q.isComplete).length,
      'extractedTextLength': extractedText.value.length,
      'quizTitle': currentQuiz.value?.title ?? 'Chưa có',
      'quizId': currentQuiz.value?.id ?? 'Chưa có',
    };
  }
}