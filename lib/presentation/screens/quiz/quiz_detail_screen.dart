import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/quiz_model.dart';
import '../../../resources/styles/colors.dart';
import '../../../resources/styles/text_styles.dart';
import '../../controllers/quiz_controller.dart';

class QuizDetailScreen extends StatelessWidget {
  final String quizId;
  const QuizDetailScreen({super.key, required this.quizId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuizController>();

    return FutureBuilder<QuizModel?>(
      future: controller.getQuizById(quizId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final quiz = snapshot.data;
        if (quiz == null) {
          return const Scaffold(body: Center(child: Text('Không tìm thấy quiz')));
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text("Làm bài QUIZ",style: AppTextStyles.headline,),

          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
                Text(quiz.title, style: Theme.of(context).textTheme.headlineSmall,
                maxLines: 2,overflow: TextOverflow.ellipsis,),
                const SizedBox(width: 20,),

              IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () => _showQuizSettingsDialog(context, quiz),
                tooltip: 'Bắt đầu làm quiz',
              ),
              if (quiz.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(quiz.description),
                ),
              if (quiz.pdfFileName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('PDF: ${quiz.pdfFileName}', style: TextStyle(color: Colors.grey[600])),
                ),
                Text('Số lượng câu: ${quiz.totalQuestions} ', style: TextStyle(color: Colors.grey[600])),
              const Divider(),
              const Text('Danh sách câu hỏi:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...quiz.questions.map((q) =>
                Card(
                  color: Colors.grey.shade50,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(q.question),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (q.options.isNotEmpty)
                        Text('Options: ${q.options.take(2).join(', ')}${q.options.length > 2 ? '...' : ''}'),
                      if (q.correctAnswer != null) ...[
                        const SizedBox(height: 4),
                        Text('Đáp án đúng: ${q.correctAnswer}', style: const TextStyle(color: Colors.green)),
                      ],
                    ],
                  ),
                  trailing: Icon(q.isComplete ? Icons.check : Icons.close, color: q.isComplete ? Colors.green : Colors.red),
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  void _showQuizSettingsDialog(BuildContext context, QuizModel quiz) {
    // Default settings
    int selectedTime = 1;
    bool shuffleQuestions = false;
    bool shuffleOptions = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // border radius 12
              side: BorderSide(color: Colors.white ,width: 1),
            ),
            title: Text(
              'Cài đặt làm quiz',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thời gian tự động chuyển sang câu tiếp theo:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<int>(
                    title: const Text('1 giây'),
                    value: 1,
                    groupValue: selectedTime,
                    activeColor: AppColors.primary,
                    onChanged: (value) => setState(() => selectedTime = value!),
                  ),
                  RadioListTile<int>(
                    title: const Text('2 giây'),
                    value: 2,
                    groupValue: selectedTime,
                    activeColor: AppColors.primary,
                    onChanged: (value) => setState(() => selectedTime = value!),
                  ),
                  CheckboxListTile(
                    title: const Text('Đảo thứ tự câu hỏi (Shuffle questions)'),
                    value: shuffleQuestions,
                    activeColor: AppColors.primary, // ✅
                    onChanged: (value) => setState(() => shuffleQuestions = value!),
                  ),
                  CheckboxListTile(
                    title: const Text('Đảo thứ tự đáp án mỗi câu (Shuffle options)'),
                    value: shuffleOptions,
                    activeColor: AppColors.primary, // ✅
                    onChanged: (value) => setState(() => shuffleOptions = value!),
                  ),
                ],

              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  textStyle: const TextStyle(fontWeight: FontWeight.w500),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(
                    '/quiz/taking/${quiz.id}',
                    extra: {
                      'autoAdvanceTime': selectedTime,
                      'shuffleQuestions': shuffleQuestions,
                      'shuffleOptions': shuffleOptions,
                    },
                  );
                },
                child: const Text('Làm bài',style: TextStyle(color: Colors.white),),
              ),
            ],
          );
        },
      ),
    );
  }


}