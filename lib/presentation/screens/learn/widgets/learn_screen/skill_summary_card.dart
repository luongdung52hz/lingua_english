import 'package:flutter/material.dart';

class SkillSummaryCard extends StatelessWidget {
  final String skill;
  final Color skillColor;
  final IconData skillIcon;
  final int totalLessons;
  final int completedLessons;

  const SkillSummaryCard({
    super.key,
    required this.skill,
    required this.skillColor,
    required this.skillIcon,
    required this.totalLessons,
    required this.completedLessons,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (totalLessons > 0 ? completedLessons / totalLessons : 0.0).clamp(0.0, 1.0); // ⭐ Sửa: Clamp progress 0-1 (tổng chỉ đến 100%)
    final progressPercent = ((completedLessons / totalLessons) * 100).clamp(0.0, 100.0).toInt(); // ⭐ Sửa: Clamp % text 0-100

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: skillColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: skillColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: skillColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(skillIcon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: skillColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.book_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Tổng: $totalLessons',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.check_circle_outline, size: 14, color: skillColor),
                    const SizedBox(width: 4),
                    Text(
                      'Đã học: $completedLessons',
                      style: TextStyle(
                        fontSize: 13,
                        color: skillColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '$progressPercent%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: skillColor,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 70,
                height: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress, // Sử dụng progress đã clamp (0-1)
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(skillColor),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}