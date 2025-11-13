import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../controllers/lesson_controller.dart';

class TopicFilterBar extends StatelessWidget {
  final LearnController controller;
  final Color skillColor;
  final String skill;

  const TopicFilterBar({
    super.key,
    required this.controller,
    required this.skillColor,
    required this.skill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(
            () {
          // Luôn có "Tất cả" làm default chip đầu, ngay cả khi topics empty
          final displayTopics = ['Tất cả', ...controller.topics];
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayTopics.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final displayName = displayTopics[index];
              final topic = displayName == 'Tất cả' ? '' : displayName; // '' cho "All"
              return Obx(() { // Per-chip Obx cho reactive isolated
                final isSelected = controller.currentTopic.value == topic;
                return GestureDetector(
                  onTap: () {
                    if (controller.currentTopic.value != topic) {
                      HapticFeedback.lightImpact();
                      // ⭐ Optimistic: Set sync cho color immediate
                      controller.currentTopic.value = topic;
                      // Branch: "Tất cả" → load full (no topic filter)
                      if (topic.isEmpty) {
                        controller.loadLessons(
                          controller.currentLevel.value,
                          skill,
                        );
                      } else {
                        // Topic cụ thể: Load filtered (non-null safe)
                        controller.loadLessonsByTopic(
                          controller.currentLevel.value,
                          skill,
                          topic, // String non-null
                        );
                      }
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? skillColor : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? skillColor : Colors.grey[300]!,
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: skillColor.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                          : null,
                    ),
                    child: Text(
                      displayName, // Hiển thị 'Tất cả' thay ''
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              });
            },
          );
        },
      ),
    );
  }
}