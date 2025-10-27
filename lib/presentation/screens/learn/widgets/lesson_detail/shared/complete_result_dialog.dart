import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../data/models/lesson_model.dart';
import 'package:lottie/lottie.dart';
import '../../../../../../resources/styles/colors.dart';

class CompleteResultDialog {
  static void show(
      BuildContext context,
      LessonModel lesson,
      int score,
      DateTime startTime,
      Map<String, String>? userAnswers,
      ) {
    final isPassed = score >= 70;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),

              // Animation & Title
              _buildHeader(isPassed),

              const SizedBox(height: 18),

              // Score Display
              _buildScoreDisplay(score, isPassed),

              const SizedBox(height: 18),

              // Stats Cards
              _buildStatsSection(lesson, userAnswers, startTime),

              const SizedBox(height: 18),

              // Message
              _buildMessage(isPassed),

              const SizedBox(height: 18),

              // Action Buttons
              _buildActions(context, isPassed),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildHeader(bool isPassed) {
    return Column(
      children: [
        // Lottie Animation
        SizedBox(
          width: 100,
          height: 100,
          child: Lottie.asset(
            isPassed
                ? 'lib/resources/assets/lottie/success.json'
                : 'lib/resources/assets/lottie/fail.json',
            width: 100,
            height: 100,
            repeat: false,
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          isPassed ? 'Xuất sắc!' : 'Cố gắng thêm nhé!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isPassed ? const Color(0xFF10B981) : const Color(0xFFFF9500),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Kết quả bài học',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  static Widget _buildScoreDisplay(int score, bool isPassed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: isPassed
            ? const Color(0xFF10B981).withOpacity(0.08)
            : const Color(0xFFFF9500).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPassed
              ? const Color(0xFF10B981).withOpacity(0.2)
              : const Color(0xFFFF9500).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPassed ? Icons.check_circle_rounded : Icons.star_rounded,
            color: isPassed ? const Color(0xFF10B981) : const Color(0xFFFF9500),
            size: 32,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Điểm số',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isPassed
                          ? const Color(0xFF10B981)
                          : const Color(0xFFFF9500),
                      height: 1.5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 2),
                    child: Text(
                      '/100',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildStatsSection(
      LessonModel lesson,
      Map<String, String>? userAnswers,
      DateTime startTime,
      ) {
    final seconds = DateTime.now().difference(startTime).inSeconds;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    final timeSpent = minutes > 0 ? '${minutes}p ${remainingSeconds}s' : '${remainingSeconds}s';

    int correctCount = 0;
    int totalQuestions = 0;

    if (userAnswers != null) {
      final questions = lesson.content['questions'] as List? ?? [];
      totalQuestions = questions.length;
      for (var q in questions) {
        final id = q['id'];
        if (userAnswers[id] == q['correctAnswer']) correctCount++;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          if (userAnswers != null) ...[
            _buildStatRow(
              icon: Icons.quiz_outlined,
              label: 'Câu trả lời',
              value: '$correctCount/$totalQuestions câu đúng',
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 12),
          ],
          _buildStatRow(
            icon: Icons.access_time_rounded,
            label: 'Thời gian',
            value: timeSpent,
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            icon: Icons.trending_up_rounded,
            label: 'Độ khó',
            value: _getDifficultyText(lesson.difficulty),
            color: const Color(0xFFEC4899),
          ),
        ],
      ),
    );
  }

  static Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  static String _getDifficultyText(dynamic difficulty) {
    if (difficulty == null) return 'Trung bình';
    final level = difficulty.toString().toLowerCase();
    if (level.contains('easy') || level == '1') return 'Dễ';
    if (level.contains('medium') || level == '2') return 'Trung bình';
    if (level.contains('hard') || level == '3') return 'Khó';
    return difficulty.toString();
  }

  static Widget _buildMessage(bool isPassed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPassed
              ? const Color(0xFF10B981).withOpacity(0.05)
              : const Color(0xFFFF9500).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isPassed
                    ? 'Chúc mừng! Bạn đã hoàn thành bài học'
                    : 'Cần đạt 70 điểm để hoàn thành',
                style: TextStyle(
                  fontSize: 14,
                  color: isPassed
                      ? const Color(0xFF059669)
                      : const Color(0xFFD97706),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildActions(BuildContext context, bool isPassed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (!isPassed) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF9500),
                  side: const BorderSide(color: Color(0xFFFF9500), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Làm lại',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/learn');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isPassed ? 'Hoàn thành' : 'Về trang chủ',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}