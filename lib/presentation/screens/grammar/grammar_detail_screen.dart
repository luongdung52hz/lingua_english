// presentation/screens/grammar/grammar_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../resources/styles/colors.dart';
import '../../controllers/grammar_controller.dart';
import '../../widgets/expanded_card.dart';

class GrammarDetailScreen extends StatelessWidget {
  final String topicId;
  final String subTopicId;

  const GrammarDetailScreen({
    super.key,
    required this.topicId,
    required this.subTopicId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GrammarController>();
    controller.selectTopic(topicId);
    controller.selectSubTopic(subTopicId);

    return Obx(() {
      final subTopic = controller.getCurrentSubTopic();
      if (subTopic == null) {
        return const Scaffold(
          body: Center(
            child: Text('Không tìm thấy nội dung'),
          ),
        );
      }

      final sectionsList = subTopic.sections.entries.toList();

      return Scaffold(
        appBar: AppBar(
          title: Text(subTopic.title),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Container(

          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sectionsList.length,
            itemBuilder: (context, index) {
              final entry = sectionsList[index];
              final section = entry.value;
              final sectionKey = entry.key;
              final isCompleted = controller.completedSections[sectionKey] ?? false;

              return ExpandableCard(
                index: index,
                title: section.title.isEmpty
                    ? 'Phần chưa có tiêu đề'
                    : section.title,
                content: section.content, // Content đã ở dạng Markdown
                examples: section.examples,
                isCompleted: isCompleted,
                onMarkComplete: () => controller.markSectionCompleted(sectionKey),
              );
            },
          ),
        ),
      );
    });
  }
}