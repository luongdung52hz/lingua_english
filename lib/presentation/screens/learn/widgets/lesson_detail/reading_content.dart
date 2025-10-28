import 'package:flutter/material.dart';
import '../../../../../data/models/lesson_model.dart';
import './shared/lesson_header.dart';
import './shared/question_list.dart';

class ReadingContent extends StatelessWidget {
  final LessonModel lesson;
  final DateTime startTime;

  const ReadingContent({
    super.key,
    required this.lesson,
    required this.startTime,
  });

  @override
  Widget build(BuildContext context) {
    final content = lesson.content;
    final text = content['text'] ?? '';
    final questions = content['questions'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LessonHeader(lesson: lesson),
          const SizedBox(height: 18),

          // Reading Text
          _buildReadingTextBox(text),
          const SizedBox(height: 24),

          // Questions
          if (questions.isNotEmpty)
            QuestionList(
              questions: questions,
              lesson: lesson,
              startTime: startTime,
            ),
        ],
      ),
    );
  }

  Widget _buildReadingTextBox(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'Bài đọc',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              height: 1.8,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}