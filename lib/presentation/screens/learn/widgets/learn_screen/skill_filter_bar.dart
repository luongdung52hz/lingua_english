import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../util/skill_untils.dart';
import '../../../../controllers/lesson_controller.dart';
import 'skill_filter_chip.dart';

class SkillFilterBar extends StatelessWidget {
  final LearnController controller;

  const SkillFilterBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: controller.skills.length,
        itemBuilder: (context, index) {
          final skill = controller.skills[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Obx(() => SkillFilterChip(
              skill: skill,
              skillColor: SkillUtils.getSkillColor(skill),
              isSelected: controller.currentSkill.value == skill,
              onTap: () => controller.changeSkill(skill),
            )),
          );
        },
      ),
    );
  }
}
