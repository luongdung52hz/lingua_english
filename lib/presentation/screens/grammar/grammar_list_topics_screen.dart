// screens/grammar_sub_topics_screen.dart - MỚI: Screen danh sách subtopics (cấp 2)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/grammar_controller.dart';
import '../../widgets/info_card.dart';

class GrammarSubTopicsScreen extends StatelessWidget {
  final String topicId;

  const GrammarSubTopicsScreen({
    super.key,
    required this.topicId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GrammarController>();
    final topic = controller.topics.firstWhereOrNull((t) => t.id == topicId);
    if (topic == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Không tìm thấy chủ đề')),
        body: const Center(child: Text('Chủ đề không tồn tại')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(topic.title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: topic.subTopics.length,
        itemBuilder: (context, index) {
          final subTopic = topic.subTopics[index];
          final completedSections = subTopic.sections.length; // Hoặc check progress thực tế
          return InfoCard(
            title: subTopic.title, // e.g., "Thì hiện tại đơn"
            subtitle: '${completedSections} phần chi tiết',
            infoPairs: [IconTextPair(Icons.book, '${completedSections} phần')],
            isCompleted: completedSections > 0, // Hoặc logic progress
            onTap: () {
              // ✅ Navigate đến chi tiết (cấp 3)
              controller.selectSubTopic(subTopic.id);
              context.push('/grammar/detail/${topicId}/${subTopic.id}');
            },
            trailing: const Icon(Icons.arrow_forward_ios),
          );
        },
      ),
    );
  }
}