import 'package:flutter/material.dart';
import '../../../../../util/skill_untils.dart';

class SkillFilterChip extends StatelessWidget {
  final String skill;
  final Color skillColor;
  final bool isSelected;
  final VoidCallback onTap;

  const SkillFilterChip({
    super.key,
    required this.skill,
    required this.skillColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? skillColor
                : skillColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? skillColor
                  : skillColor.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: skillColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ]
                : [],
          ),
          child: Row(
            children: [
              Icon(
                SkillUtils.getSkillIcon(skill),
                color: isSelected ? Colors.white : skillColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                skill.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : skillColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}