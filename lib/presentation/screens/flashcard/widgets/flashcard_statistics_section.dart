// lib/ui/widgets/flashcard_statistics_section.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/flashcard_controller.dart';
import 'stat_card.dart';

class FlashcardStatisticsSection extends StatelessWidget {
  const FlashcardStatisticsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FlashcardController>();

    return Obx(() {
      final stats = controller.statistics;
      final total = stats['total'] ?? 0;
      final memorized = stats['memorized'] ?? 0;
      final toReview = stats['toReview'] ?? 0;

      return Container(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Tổng số',
                value: total,
                color: Colors.blue[600]!,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                label: 'Đã thuộc',
                value: memorized,
                color: Colors.green[600]!,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                label: 'Cần học',
                value: toReview,
                color: Colors.orange[400]!,
              ),
            ),
          ],
        ),
      );
    });
  }
}