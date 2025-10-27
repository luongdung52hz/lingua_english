import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home_controller.dart';

/// Widget hiển thị daily progress + streak trên home screen
class DailyProgressWidget extends StatelessWidget {
  const DailyProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Obx(() {
      final daily = controller.dailyCompleted.value;
      final target = controller.targetDaily.value;
      final streak = controller.dailyStreak.value;
      final progress = target > 0 ? daily / target : 0.0;
      final isComplete = daily >= target;

      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isComplete
                ? [Colors.green.shade400, Colors.green.shade600]
                : [Colors.blue.shade400, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isComplete ? Colors.green : Colors.blue).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isComplete ? '🎉 Mục tiêu hoàn thành!' : '📚 Mục tiêu hôm nay',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$daily/$target bài học',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                // Streak badge
                _buildStreakBadge(streak),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),

            const SizedBox(height: 12),

            // Status message
            Text(
              _getStatusMessage(daily, target, isComplete),
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStreakBadge(int streak) {
    if (streak == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            const Text(
              'Start',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            'ngày',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusMessage(int daily, int target, bool isComplete) {
    if (isComplete) {
      return '✅ Xuất sắc! Bạn đã hoàn thành mục tiêu hôm nay!';
    }

    final remaining = target - daily;
    if (remaining == 1) {
      return '💪 Còn 1 bài nữa thôi! Cố lên!';
    }

    return '💪 Còn $remaining bài nữa để đạt mục tiêu!';
  }
}

/// Streak milestone widget (hiển thị khi đạt mốc)
class StreakMilestoneDialog extends StatelessWidget {
  final int streak;

  const StreakMilestoneDialog({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    final milestone = _getMilestone(streak);
    if (milestone == null) return const SizedBox.shrink();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            milestone.emoji,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            milestone.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            milestone.message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Tuyệt vời!'),
          ),
        ],
      ),
    );
  }

  ({String emoji, String title, String message})? _getMilestone(int streak) {
    switch (streak) {
      case 7:
        return (
        emoji: '🎯',
        title: '7 ngày streak!',
        message: 'Bạn đã học liên tục 1 tuần. Tuyệt vời!',
        );
      case 14:
        return (
        emoji: '🏆',
        title: '14 ngày streak!',
        message: 'Học liên tục 2 tuần! Bạn thật kiên trì!',
        );
      case 30:
        return (
        emoji: '🌟',
        title: '30 ngày streak!',
        message: '1 tháng liên tục! Bạn là champion!',
        );
      case 100:
        return (
        emoji: '💎',
        title: '100 ngày streak!',
        message: 'Thành tích đáng kinh ngạc! Bạn là huyền thoại!',
        );
      default:
        return null;
    }
  }
}

/// Helper function để show milestone dialog
void showStreakMilestone(BuildContext context, int streak) {
  // Check if milestone
  if ([7, 14, 30, 100].contains(streak)) {
    showDialog(
      context: context,
      builder: (context) => StreakMilestoneDialog(streak: streak),
    );
  }
}