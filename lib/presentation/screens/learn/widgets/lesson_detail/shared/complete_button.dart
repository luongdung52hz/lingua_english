import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../data/models/lesson_model.dart';
import '../../../../../controllers/lesson_controller.dart';
import '../../../../../../resources/styles/colors.dart';
import 'complete_result_dialog.dart';

class CompleteButton extends StatelessWidget {
  final LessonModel lesson;
  final DateTime startTime;
  final Map<String, String>? userAnswers;
  final int? customScore;

  const CompleteButton({
    super.key,
    required this.lesson,
    required this.startTime,
    this.userAnswers,
    this.customScore,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleComplete(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'HOÀN THÀNH BÀI HỌC',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleComplete(BuildContext context) {
    final controller = Get.find<LearnController>();
    int finalScore = 0;

    // 1️⃣ Tính điểm theo loại bài học
    if (lesson.skill == 'listening' || lesson.skill == 'reading') {
      if (userAnswers != null) {
        finalScore = _calculateQuestionScore(lesson, userAnswers!);
      }
    } else if (lesson.skill == 'speaking' || lesson.skill == 'writing') {
      finalScore = customScore ?? 0;

      if (finalScore == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng hoàn thành bài và chấm điểm trước!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // 2️⃣ Gửi dữ liệu hoàn thành bài
    final timeSpent = DateTime.now().difference(startTime).inSeconds;
    controller.completeLesson(lesson, finalScore, timeSpent);

    // 3️⃣ Hiển thị kết quả
    CompleteResultDialog.show(context, lesson, finalScore, startTime, userAnswers);
  }

  // ⭐ NEW: Method local tính score (tránh phụ thuộc dialog)
  static int _calculateQuestionScore(LessonModel lesson, Map<String, String> answers) {
    final questions = lesson.content['questions'] as List? ?? [];
    if (questions.isEmpty) return 0;

    int correctCount = 0;
    for (var question in questions) {
      final questionId = question['id'];
      final correctAnswer = question['correctAnswer'];
      if (answers[questionId] == correctAnswer) correctCount++;
    }

    return ((correctCount / questions.length) * 100).toInt();
  }
}