import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/lesson_controller.dart';
import '../../../../widgets/info_card.dart';

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
    return Obx(() {
      if (controller.isLoading.value)
        return const Center(child: CircularProgressIndicator());
      if (controller.error.value != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Không thể tải bài học.'),
              TextButton(
                onPressed: () => controller.loadLessons(
                  controller.currentLevel.value,
                  controller.currentSkill.value,
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        );
      }
      return controller.lessons.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có bài học',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              // padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10,),
              itemCount: controller.lessons.length,
              itemBuilder: (context, index) {
                final lesson = controller.lessons[index];

                return InfoCard(
                  title: lesson.title,
                  subtitle: lesson.description,
                  infoPairs: [
                    IconTextPair(Icons.access_time, '${lesson.duration} phút'),
                    IconTextPair(Icons.stars, 'Độ khó: ${lesson.difficulty}/5'),
                  ],

                  onTap: () => onLessonTap(lesson),
                );
              },
            );
    });
  }
}
