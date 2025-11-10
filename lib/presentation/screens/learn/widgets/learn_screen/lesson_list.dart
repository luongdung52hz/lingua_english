import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/lesson_controller.dart';
import '../../../../learn/widgets/lesson_card.dart';


class LessonList extends StatelessWidget {
  final LearnController controller;
  final Function(dynamic) onLessonTap;

  const LessonList({
    super.key,
    required this.controller,
    required this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => controller.lessons.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có bài học',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.only(bottom: 14),
        itemCount: controller.lessons.length,
        itemBuilder: (context, index) {
          final lesson = controller.lessons[index];
          return LessonCard(
            lesson: lesson,
            onTap: () => onLessonTap(lesson),
          );
        },
      ),
    );
  }
}