import 'dart:io';
import 'package:get/get.dart';
import '../../data/datasources/remote/ai/ai_quiz_service.dart';
import '../../data/datasources/remote/pdf_service.dart';
import '../../data/models/quiz_model.dart';
import '../../data/models/question_model.dart';
import '../../data/repositories/quiz_repository.dart';

class PdfController extends GetxController {
  final PDFService _pdfService = PDFService();
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

  // ✅ ID generator
  String _generateId() {
    return 'quiz_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  @override
  void onInit() {
    super.onInit();
    _aiService = AIQuizService(apiKey: 'AIzaSyBl_JBlqSWCh5QcwrnNKW5SjR4sw6InMOM');
  }

  /// Main: Process PDF -> AI parse -> quiz
  Future<void> processPdfFile(File file) async {
    try {
      isProcessing.value = true;
      errorMessage.value = '';
      progress.value = 0.0;

      // Stage 1: Extract text from PDF
      await _extractTextFromPdf(file);

      // Stage 2: Use AI to parse text into questions JSON
      await _parseQuestionsWithAI();

      // Stage 3: Generate quiz metadata
      await _generateQuizMetadata(file);

      // Stage 4: Save to Firebase
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

  /// Stage 1: Extract text
  Future<void> _extractTextFromPdf(File file) async {
    processingStage.value = '📄 Đang đọc file PDF...';
    progress.value = 0.2;

    try {
      var rawText = await _pdfService.extractText(file);

      // 🔹 Pre-clean: Xử lý format quiz đặc biệt (loại bỏ Câu n (Một đáp án), trích xuất câu hỏi từ HA(n) = "...")
      rawText = _preCleanQuizFormat(rawText);

      // 🔹 Pre-clean: Sửa sơ bộ chữ tiếng Việt bị tách (OCR error, e.g., "T r ì n h" → "Trình")
     // rawText = _preNormalizeBrokenVietnamese(rawText);

      extractedText.value = rawText;

      if (extractedText.value.isEmpty) {
        throw Exception('File PDF không chứa văn bản có thể đọc được');
      }

      print('✅ Đã trích xuất và làm sạch ${extractedText.value.length} ký tự');
    } catch (e) {
      throw Exception('Lỗi đọc PDF: $e');
    }
  }

  /// 🔹 Pre-clean: Xử lý format quiz (loại bỏ noise, trích xuất câu hỏi từ HA(n))
  String _preCleanQuizFormat(String text) {
    return text
    // Loại bỏ dòng "Câu n (Một đáp án)" (đã có filter ở service, nhưng đảm bảo)
        .split('\n')
        .map((line) {
      line = line.trim();
      if (RegExp(r'^Câu \d+ \(.+\)$').hasMatch(line)) return '';  // Bỏ dòng này

      // Trích xuất câu hỏi từ "HA(n) = “question”" → chỉ giữ "question"
      if (RegExp(r'^HA\(\d+\)\s*=\s*[“""]?(.+?)[“"""]?\s*$').hasMatch(line)) {
        final match = RegExp(r'^HA\(\d+\)\s*=\s*[“""]?(.+?)[“"""]?\s*$').firstMatch(line);
        return match?.group(1)?.trim() ?? line;  // Giữ phần trong quotes
      }

      // Giữ nguyên options (dòng bắt đầu bằng " *" hoặc " ")
      if (line.startsWith('"') || line.startsWith('*')) return line;

      return line;
    })
        .where((line) => line.isNotEmpty)
        .join('\n')
        .trim();
  }


 /// Stage 2: Parse questions with AI (all-in-one)
  Future<void> _parseQuestionsWithAI() async {
    processingStage.value = '🤖 AI đang phân tích câu hỏi...';
    progress.value = 0.4;

    try {
      // Truyền text đã pre-clean
      parsedQuestions.value =
      await _aiService.parseTextToJSON(extractedText.value);

      if (parsedQuestions.isEmpty) {
        throw Exception('AI không trích xuất được câu hỏi nào');
      }

      print('✅ AI đã tạo ${parsedQuestions.length} câu hỏi');

      // Kiểm tra câu hỏi chưa có đáp án
      final incompleteCount =
          parsedQuestions.where((q) => !q.isComplete).length;
      if (incompleteCount > 0) {
        print(
            '⚠️ Vẫn còn $incompleteCount câu chưa có đáp án, AI sẽ bổ sung tự động');
      }

      progress.value = 0.6;
    } catch (e) {
      throw Exception('Lỗi AI parse câu hỏi: $e');
    }
  }

  /// Stage 3: Generate quiz metadata
  Future<void> _generateQuizMetadata(File file) async {
    processingStage.value = '📝 Đang tạo thông tin quiz...';
    progress.value = 0.8;

    try {
      // 🔹 Tạo text tóm tắt từ questions để AI đặt tiêu đề
      final sampleText = parsedQuestions
          .take(3)
          .map((q) => q.question)
          .join('\n');

      // Fallback nếu method generateQuizTitle không tồn tại trong AIQuizService
      String title = 'Quiz từ PDF';  // Default title
      try {
        title = await _aiService.generateQuizTitle(sampleText);
      } catch (e) {
        print('⚠️ Lỗi generate title: $e. Sử dụng default.');
      }

      currentQuiz.value = QuizModel(
        id: _generateId(),
        title: title,
        description: 'Quiz được tạo từ file PDF',
        questions: parsedQuestions,
        createdAt: DateTime.now(),
        pdfFileName: file.path.split('/').last,
        totalQuestions: parsedQuestions.length,
        status: QuizStatus.draft,
      );

      print('✅ Đã tạo quiz: ${currentQuiz.value?.title ?? 'Chưa có tiêu đề'}');
    } catch (e) {
      throw Exception('Lỗi tạo metadata: $e');
    }
  }

  /// Stage 4: Save to Firebase
  Future<void> _saveQuizToFirebase() async {
    if (currentQuiz.value == null) {
      throw Exception('Quiz chưa được tạo');
    }

    processingStage.value = '☁️ Đang lưu lên Firebase...';
    progress.value = 0.9;

    try {
      final quizId = await _quizRepository.saveQuiz(currentQuiz.value!);

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

  /// Preview mode
  Future<QuizModel> previewPdfFile(File file) async {
    await _extractTextFromPdf(file);
    await _parseQuestionsWithAI();

    return QuizModel(
      id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
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

  void removeQuestion(int index) {
    if (index >= 0 && index < parsedQuestions.length) {
      parsedQuestions.removeAt(index);
    }
  }

  void clear() {
    extractedText.value = '';
    parsedQuestions.clear();
    currentQuiz.value = null;
    errorMessage.value = '';
    progress.value = 0.0;
  }

  Map<String, dynamic> getProcessingSummary() {
    return {
      'totalQuestions': parsedQuestions.length,
      'completeQuestions': parsedQuestions.where((q) => q.isComplete).length,
      'incompleteQuestions':
      parsedQuestions.where((q) => !q.isComplete).length,
      'extractedTextLength': extractedText.value.length,
      'quizTitle': currentQuiz.value?.title ?? 'Chưa có',
      'quizId': currentQuiz.value?.id ?? 'Chưa có',
    };
  }
}