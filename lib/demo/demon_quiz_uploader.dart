// lib/utils/demo_quiz_uploader.dart
import 'package:get/get.dart';
import 'package:learn_english/demo/question_demon.dart';
import '../data/models/quiz_model.dart';
import 'package:uuid/uuid.dart';

import '../presentation/controllers/quiz_controller.dart';

Future<void> uploadDemoQuiz() async {
  final QuizController controller = Get.find<QuizController>();

  final quiz = QuizModel(
    id: const Uuid().v4(),
    title: 'Demo Quiz',
    description: 'Quiz tự động tạo khi chạy app',
    questions: demoQuestions,
    createdAt: DateTime.now(),
    createdBy: 'system',
    totalQuestions: demoQuestions.length,
    pdfFileName: null,
  );

  try {
    await controller.createQuiz(quiz);
    print('✅ Demo quiz đã được lưu lên database');
  } catch (e) {
    print('❌ Lỗi khi lưu demo quiz: $e');
  }
}
