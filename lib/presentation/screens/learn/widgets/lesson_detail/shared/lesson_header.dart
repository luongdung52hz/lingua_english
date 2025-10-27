import 'package:flutter/material.dart';
import '../../../../../../data/models/lesson_model.dart';

class LessonHeader extends StatelessWidget {
  final LessonModel lesson;

  const LessonHeader({
    super.key,
    required this.lesson,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getSkillColor(lesson.skill).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                lesson.level,
                style: TextStyle(
                  color: _getSkillColor(lesson.skill),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              '${lesson.duration} phút',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const Spacer(),
            _buildDifficultyStars(lesson.difficulty),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          lesson.description,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyStars(int difficulty) {
    return Row(
      children: List.generate(3, (index) {
        return Icon(
          index < difficulty ? Icons.star : Icons.star_border,
          size: 16,
          color: Colors.amber,
        );
      }),
    );
  }

  Color _getSkillColor(String skill) {
    switch (skill) {
      case 'listening':
        return Colors.blue;
      case 'speaking':
        return Colors.orange;
      case 'reading':
        return Colors.green;
      case 'writing':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}