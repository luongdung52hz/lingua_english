import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../../../widgets/app_button.dart';
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
        child: CustomButton(
          onPressed: () => _handleComplete(context),
          text: 'HOÀN THÀNH BÀI HỌC',
          icon: Icons.check_circle,
          iconSize: 20,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          borderRadius: BorderRadius.circular(12),
        )
    );
  }

  void _handleComplete(BuildContext context) {
    final controller = Get.find<LearnController>();
    int finalScore = 0;

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

    final timeSpent = DateTime.now().difference(startTime).inSeconds;
    controller.completeLesson(lesson, finalScore, timeSpent);

    CompleteResultDialog.show(context, lesson, finalScore, startTime, userAnswers);
  }

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