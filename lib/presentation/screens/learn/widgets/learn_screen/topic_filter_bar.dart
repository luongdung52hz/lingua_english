import 'package:flutter/material.dart';
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
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(
            () => ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.topics.length,
          itemBuilder: (context, index) {
            final topic = controller.topics[index];
            final isSelected = controller.currentTopic.value == topic;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(
                  topic,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                backgroundColor: isSelected ? skillColor : Colors.grey[200],
                side: BorderSide(
                  color: isSelected ? skillColor : Colors.grey[300]!,
                  width: 1,
                ),
                elevation: isSelected ? 2 : 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onPressed: () {
                  controller.loadLessonsByTopic(
                    controller.currentLevel.value,
                    skill,
                    topic

                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
