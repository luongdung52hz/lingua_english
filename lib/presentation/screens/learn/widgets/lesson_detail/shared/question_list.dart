import 'package:flutter/material.dart';
import '../../../../../../data/models/lesson_model.dart';
import '../../../../../../resources/styles/colors.dart';
import './complete_button.dart';

class QuestionList extends StatefulWidget {
  final List questions;
  final LessonModel lesson;
  final DateTime startTime;

  const QuestionList({
    super.key,
    required this.questions,
    required this.lesson,
    required this.startTime,
  });

  @override
  State<QuestionList> createState() => _QuestionListState();
}

class _QuestionListState extends State<QuestionList> {
  final Map<String, String> userAnswers = {};
  int currentQuestionIndex = 0;

  void _nextQuestion() {
    if (currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Câu hỏi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${currentQuestionIndex + 1}/${widget.questions.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildQuestionCard(currentQuestionIndex, widget.questions[currentQuestionIndex] as Map),
        const SizedBox(height: 16),
        _buildNavigationButtons(),
        const SizedBox(height: 24),
        if (currentQuestionIndex == widget.questions.length - 1)
          CompleteButton(
            lesson: widget.lesson,
            startTime: widget.startTime,
            userAnswers: userAnswers,
          ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Nút Previous
        if (currentQuestionIndex > 0)
          ElevatedButton.icon(
            onPressed: _previousQuestion,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Câu trước'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
        else
          const SizedBox.shrink(),

        // Nút Next
        if (currentQuestionIndex < widget.questions.length - 1)
          ElevatedButton.icon(
            onPressed: _nextQuestion,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Câu tiếp'),
            iconAlignment: IconAlignment.end,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildQuestionCard(int index, Map question) {
    final questionId = question['id'] ?? 'q$index';
    final questionText = question['question'] ?? '';
    final options = question['options'] as List? ?? [];

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.grey.shade50,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    questionText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...options.map((option) => _buildOptionTile(questionId, option)),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(String questionId, dynamic option) {
    final isSelected = userAnswers[questionId] == option;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            userAnswers[questionId] = option.toString();
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.transparent,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.toString(),
                  style: TextStyle(
                    fontSize: 15,
                    color: isSelected ? Colors.blue.shade900 : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}