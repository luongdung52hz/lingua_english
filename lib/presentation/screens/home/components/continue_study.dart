import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:get/get.dart';
import '../../../widgets/app_button.dart';
import '../../../../resources/styles/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../controllers/home_controller.dart';

class ContinueStudyWidget extends StatelessWidget {
  final VoidCallback? onContinueTap;

  const ContinueStudyWidget({
    super.key,
    this.onContinueTap,
  });

  @override
  Widget build(BuildContext context) {
    final homeCtrl = Get.find<HomeController>();

    return Obx(() {
      final dailyPercentage = homeCtrl.targetDaily.value > 0
          ? (homeCtrl.dailyCompleted.value / homeCtrl.targetDaily.value) * 100
          : 0.0;

      final isGoalReached = homeCtrl.dailyCompleted.value >= homeCtrl.targetDaily.value;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 3),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tiếp tục học hôm nay",
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildProgressCircle(dailyPercentage),
                const SizedBox(width: 16),
                Expanded(child: _buildStatsCard(homeCtrl, isGoalReached)),
              ],
            ),
            const SizedBox(height: 12),
            _buildActionButton(isGoalReached),
          ],
        ),
      );
    });
  }

  Widget _buildProgressCircle(double percentage) {
    return CircularPercentIndicator(
      radius: 42.0,
      lineWidth: 5.0,
      percent: (percentage / 100).clamp(0.0, 1.0),
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${percentage.clamp(0.0, 100.0).toStringAsFixed(0)}%",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(
            "hoàn thành",
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      progressColor: AppColors.primary,
      backgroundColor: Colors.grey.withOpacity(0.2),
      circularStrokeCap: CircularStrokeCap.round,
    );
  }

  Widget _buildStatsCard(HomeController homeCtrl, bool isGoalReached) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatRow(
            icon: Icons.today,
            label: "Hôm nay",
            value: "${homeCtrl.dailyCompleted.value}/${homeCtrl.targetDaily.value}",
            color: isGoalReached ? Colors.green : AppColors.primary,
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            icon: Icons.emoji_events,
            label: "Điểm số",
            value: "${homeCtrl.dailyStreak.value}",
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          "$label: ",
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(bool isGoalReached) {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        onPressed: onContinueTap,
        text: isGoalReached ? "✓ Mục tiêu đã đạt!" : "Tiếp tục học →",
        fontWeight: FontWeight.w600,
        isLoading: false,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}