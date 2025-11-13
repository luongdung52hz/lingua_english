import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../../../../resources/styles/colors.dart';
import '../../data/models/lesson_model.dart';

// Model cho một stat item để dễ tái sử dụng
class StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

// Model cho button config để dễ tái sử dụng
class ButtonConfig {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary; // true: ElevatedButton, false: OutlinedButton
  final Color? primaryColor;
  final Color? secondaryColor;

  const ButtonConfig({
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.primaryColor,
    this.secondaryColor,
  });
}

class GenericResultDialog {
  // Static method chính để show dialog chung
  static void show(
      BuildContext context, {
        // Core params (required cho logic cơ bản)
        required bool isSuccess,
        required String successTitle,
        required String failTitle,
        required String subtitle,
        // Optional messages
        String? successMessage,
        String? failMessage,
        // Score (optional nếu showScore=false)
        String? scoreLabel,
        int? score,
        int totalScore = 100,
        // Icons & Colors (defaults có sẵn)
        IconData? successIcon,
        IconData? failIcon,
        Color? successColor,
        Color? failColor,
        // Stats & Buttons (có thể rỗng)
        List<StatItem> stats = const [],
        List<ButtonConfig> buttons = const [],
        // Animations (defaults có sẵn)
        String? successAnimationPath,
        String? failAnimationPath,
        double animationSize = 100,
        // Toggles
        bool showScore = true,
      }) {
    // Defaults cho animations nếu không cung cấp
    final defaultSuccessPath = 'lib/resources/assets/lottie/success.json';
    final defaultFailPath = 'lib/resources/assets/lottie/fail.json';
    final animSuccess = successAnimationPath ?? defaultSuccessPath;
    final animFail = failAnimationPath ?? defaultFailPath;

    // Defaults cho buttons nếu rỗng (ví dụ: nút đóng mặc định)
    final effectiveButtons = buttons.isEmpty ? [
      ButtonConfig(
        text: isSuccess ? 'OK' : 'Thử lại',
        onPressed: () => Navigator.of(context).pop(),
        isPrimary: true,
      ),
    ] : buttons;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: _buildDialogContent(
          context,
          isSuccess: isSuccess,
          successTitle: successTitle,
          failTitle: failTitle,
          subtitle: subtitle,
          successMessage: successMessage,
          failMessage: failMessage,
          scoreLabel: scoreLabel,
          score: score ?? 0,
          totalScore: totalScore,
          successIcon: successIcon,
          failIcon: failIcon,
          successColor: successColor,
          failColor: failColor,
          stats: stats,
          buttons: effectiveButtons,
          successAnimationPath: animSuccess,
          failAnimationPath: animFail,
          animationSize: animationSize,
          showScore: showScore,
        ),
      ),
    );
  }

  // Private method build nội dung dialog
  static Widget _buildDialogContent(
      BuildContext context, {
        required bool isSuccess,
        required String successTitle,
        required String failTitle,
        required String subtitle,
        String? successMessage,
        String? failMessage,
        String? scoreLabel,
        required int score,
        required int totalScore,
        IconData? successIcon,
        IconData? failIcon,
        Color? successColor,
        Color? failColor,
        required List<StatItem> stats,
        required List<ButtonConfig> buttons,
        required String successAnimationPath,
        required String failAnimationPath,
        required double animationSize,
        bool showScore = true,
      }) {
    final title = isSuccess ? successTitle : failTitle;
    final message = isSuccess ? (successMessage ?? '') : (failMessage ?? '');
    final currentColor = isSuccess ? (successColor ?? const Color(0xFF10B981)) : (failColor ?? const Color(0xFFFF9500));
    final currentIcon = isSuccess ? (successIcon ?? Icons.check_circle_rounded) : (failIcon ?? Icons.star_rounded);
    final animationPath = isSuccess ? successAnimationPath : failAnimationPath;
    final effectiveScoreLabel = scoreLabel ?? 'Điểm số';

    return Container(
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
          // Header: Animation & Title
          _buildHeader(
            title: title,
            subtitle: subtitle,
            animationPath: animationPath,
            animationSize: animationSize,
            color: currentColor,
          ),
          const SizedBox(height: 18),
          // Score Display (tùy chọn)
          if (showScore && scoreLabel != null) ...[
            _buildScoreDisplay(
              score: score,
              totalScore: totalScore,
              label: effectiveScoreLabel,
              icon: currentIcon,
              color: currentColor,
            ),
            const SizedBox(height: 18),
          ],
          // Stats Section
          if (stats.isNotEmpty) ...[
            _buildStatsSection(stats),
            const SizedBox(height: 18),
          ],
          // Message
          if (message.isNotEmpty) ...[
            _buildMessage(message, color: currentColor),
            const SizedBox(height: 18),
          ],
          // Actions
          _buildActions(buttons),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  static Widget _buildHeader({
    required String title,
    required String subtitle,
    required String animationPath,
    required double animationSize,
    required Color color,
  }) {
    return Column(
      children: [
        // Lottie Animation
        SizedBox(
          width: animationSize,
          height: animationSize,
          child: Lottie.asset(
            animationPath,
            width: animationSize,
            height: animationSize,
            repeat: false,
          ),
        ),
        const SizedBox(height: 16),
        // Title
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  static Widget _buildScoreDisplay({
    required int score,
    required int totalScore,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
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
                      color: color,
                      height: 1.5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 2),
                    child: Text(
                      '/$totalScore',
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

  static Widget _buildStatsSection(List<StatItem> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: stats.map((stat) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildStatRow(
            icon: stat.icon,
            label: stat.label,
            value: stat.value,
            color: stat.color,
          ),
        )).toList(),
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

  static Widget _buildMessage(String message, {required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildActions(List<ButtonConfig> buttons) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: buttons.map((button) {
          Widget buttonWidget;
          if (button.isPrimary) {
            // ElevatedButton
            buttonWidget = ElevatedButton(
              onPressed: button.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: button.primaryColor ?? AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                button.text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          } else {
            // OutlinedButton
            buttonWidget = OutlinedButton(
              onPressed: button.onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: button.secondaryColor ?? const Color(0xFFFF9500),
                side: BorderSide(
                  color: button.secondaryColor ?? const Color(0xFFFF9500),
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                button.text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: button.secondaryColor ?? const Color(0xFFFF9500),
                ),
              ),
            );
          }

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: buttons.last == button ? 0 : 12),
              child: buttonWidget,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Wrapper method cho trường hợp bài học cũ (để dễ migrate)
class CompleteResultDialog {
  static void show(
      BuildContext context,
      LessonModel lesson,
      int score,
      DateTime startTime,
      Map<String, String>? userAnswers,
      ) {
    final isPassed = score >= 70;
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

    final stats = <StatItem>[
      if (userAnswers != null)
        StatItem(
          icon: Icons.quiz_outlined,
          label: 'Câu trả lời',
          value: '$correctCount/$totalQuestions câu đúng',
          color: const Color(0xFF3B82F6),
        ),
      StatItem(
        icon: Icons.access_time_rounded,
        label: 'Thời gian',
        value: timeSpent,
        color: const Color(0xFF8B5CF6),
      ),
      StatItem(
        icon: Icons.trending_up_rounded,
        label: 'Độ khó',
        value: _getDifficultyText(lesson.difficulty),
        color: const Color(0xFFEC4899),
      ),
    ];

    final buttons = <ButtonConfig>[
      if (!isPassed)
        ButtonConfig(
          text: 'Làm lại',
          onPressed: () => Navigator.of(context).pop(),
          isPrimary: false,
          secondaryColor: const Color(0xFFFF9500),
        ),
      ButtonConfig(
        text: isPassed ? 'Hoàn thành' : 'Về trang chủ',
        onPressed: () {
          Navigator.of(context).pop();
          context.go('/learn');
        },
        isPrimary: true,
        primaryColor: AppColors.primary,
      ),
    ];

    GenericResultDialog.show(
      context,
      isSuccess: isPassed,
      successTitle: 'Xuất sắc!',
      failTitle: 'Cố gắng thêm nhé!',
      subtitle: 'Kết quả bài học',
      successMessage: 'Chúc mừng! Bạn đã hoàn thành bài học',
      failMessage: 'Cần đạt 70 điểm để hoàn thành',
      scoreLabel: 'Điểm số',
      score: score,
      totalScore: 100,
      successIcon: Icons.check_circle_rounded,
      failIcon: Icons.star_rounded,
      successColor: const Color(0xFF10B981),
      failColor: const Color(0xFFFF9500),
      stats: stats,
      buttons: buttons,
      successAnimationPath: 'lib/resources/assets/lottie/success.json',
      failAnimationPath: 'lib/resources/assets/lottie/fail.json',
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
}