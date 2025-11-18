// screens/grammar_sub_topics_screen.dart - MỚI: Screen danh sách subtopics (cấp 2)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_english/resources/styles/colors.dart';
import '../../../resources/styles/text_styles.dart';
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
        appBar: AppBar(title: const Text('Không tìm thấy chủ đề',)),
        body: const Center(child: Text('Chủ đề không tồn tại',)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
          title: Text(topic.title,),
          iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primary,
      ),

      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical:12 ),
        itemCount: topic.subTopics.length,
        itemBuilder: (context, index) {
          final subTopic = topic.subTopics[index];
          final completedSections = subTopic.sections.length; // Hoặc check progress thực tế
          return InfoCard(
            title: subTopic.title,
            subtitle: '${completedSections} phần chi tiết',
            infoPairs: [IconTextPair(Icons.book, '${completedSections} phần')],
            isCompleted: false,
            onTap: () {
              controller.selectSubTopic(subTopic.id);
              context.push('/grammar/detail/${topicId}/${subTopic.id}');
            },
            trailing: const Icon(Icons.arrow_forward_ios,color: Colors.grey,),
          );
        },
      ),
    );
  }
}