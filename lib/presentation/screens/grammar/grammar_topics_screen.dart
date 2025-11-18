// screens/grammar_topics_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:go_router/go_router.dart'; // Import cho navigate

import '../../../resources/styles/colors.dart';
import '../../../resources/styles/text_styles.dart';
import '../../controllers/grammar_controller.dart';
import '../../widgets/info_card.dart';

class GrammarTopicsScreen extends StatelessWidget {
  const GrammarTopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GrammarController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ngữ Pháp',style: AppTextStyles.headlinew),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primary,),
      body: Obx(() => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical:12 ),
        itemCount: controller.topics.length,
        itemBuilder: (context, index) {
          final topic = controller.topics[index];
          final completedSubs = topic.subTopics.where((s) => /* check progress - ví dụ: controller.completedSections.containsKey(s.id) */ false).length; // Thay logic check progress thực tế nếu có
          return InfoCard(
            title: topic.title,
            subtitle: '${completedSubs}/${topic.subTopics.length} mục con hoàn thành',
            infoPairs: [IconTextPair(Icons.folder, '${topic.subTopics.length} mục con')],
            isCompleted: completedSubs == topic.subTopics.length,
            onTap: () {
              controller.selectTopic(topic.id);
              context.push('/grammar/subtopics/${topic.id}');
            },
            trailing: const Icon(Icons.arrow_forward_ios,color: Colors.grey,),
          );
        },
      )),
    );
  }
}