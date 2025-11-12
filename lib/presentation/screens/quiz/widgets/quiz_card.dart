import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/quiz_model.dart';
import '../quiz_detail_screen.dart';

class QuizCard extends StatelessWidget {
  final QuizModel quiz;
  const QuizCard({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade50,
      key: key,
      margin: const EdgeInsets.all(3),
      child: ListTile(
        title: Text(quiz.title),
        subtitle: Text('${quiz.totalQuestions} câu hỏi'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => context.push('/quiz/detail/${quiz.id}'),
      ),
    );
  }
}