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
      // Tính % hôm nay (daily)
      double dailyPercentage = 0.0;
      if (homeCtrl.targetDaily.value > 0) {
        dailyPercentage = (homeCtrl.dailyCompleted.value / homeCtrl.targetDaily.value) * 100;
      }

      // Tính % tổng (cumulative)
      double totalPercentage = 0.0;
      if (homeCtrl.totalLessons.value > 0) {
        totalPercentage = (homeCtrl.completedLessons.value / homeCtrl.totalLessons.value) * 100;
      }

      bool dailyGoalReached = homeCtrl.dailyCompleted.value >= homeCtrl.targetDaily.value;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircularPercentIndicator(
                  radius: 50.0,
                  lineWidth: 6.0,
                  percent: (dailyPercentage / 100).clamp(0.0, 1.0),
                  center: Text(
                    "${(dailyPercentage.clamp(0.0, 100.0)).toStringAsFixed(1)}%",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  progressColor: AppColors.primary,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Material(
                    color: Colors.white,
                    elevation: 2,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bài đã làm: ${homeCtrl.completedLessons.value}/${homeCtrl.totalLessons.value}",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Hôm nay: ${homeCtrl.dailyCompleted.value}/${homeCtrl.targetDaily.value}",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: dailyGoalReached ? Colors.green : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Điểm số: ${homeCtrl.dailyStreak.value}",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: onContinueTap,
                text: dailyGoalReached ? "Mục tiêu hôm nay đạt!" : "Tiếp tục học",
                fontWeight: FontWeight.w900,
                isLoading: false,
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      );
    });
  }
}