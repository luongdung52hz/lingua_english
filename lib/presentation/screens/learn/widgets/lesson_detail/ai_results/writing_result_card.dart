import 'package:flutter/material.dart';
import 'package:learn_english/presentation/screens/learn/widgets/lesson_detail/ai_results/score_result.dart';
import '../../../../../../data/datasources/remote/ai/models/writing_result.dart';


class WritingResultCard extends StatelessWidget {
  final WritingResult result;

  const WritingResultCard({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 24),
            _buildScores(),
            const SizedBox(height: 20),
            _buildFeedback(),
            const SizedBox(height: 16),
            _buildWordCountStatus(),
            const SizedBox(height: 16),
            if (result.strengths.isNotEmpty) ...[
              _buildStrengths(),
              const SizedBox(height: 12),
            ],
            if (result.improvements.isNotEmpty) ...[
              _buildImprovements(),
              const SizedBox(height: 12),
            ],
            if (result.grammarErrors.isNotEmpty) ...[
              _buildGrammarErrors(),
              const SizedBox(height: 12),
            ],
            if (result.vocabularySuggestions.isNotEmpty)
              _buildVocabularySuggestions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Icon(Icons.auto_awesome, color: Colors.purple, size: 28),
        SizedBox(width: 12),
        Text(
          'Đánh giá AI',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildScores() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ScoreCircle(label: 'Tổng', score: result.score, color: Colors.purple),
        ScoreCircle(label: 'Ngữ pháp', score: result.grammarScore, color: Colors.blue),
        ScoreCircle(label: 'Từ vựng', score: result.vocabularyScore, color: Colors.green),
        ScoreCircle(label: 'Cấu trúc', score: result.structureScore, color: Colors.orange),
      ],
    );
  }

  Widget _buildFeedback() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.comment, color: Colors.purple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.feedback,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCountStatus() {
    return Row(
      children: [
        Icon(
          result.meetsRequirements ? Icons.check_circle : Icons.warning,
          color: result.meetsRequirements ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 8),
        Text(
          'Số từ: ${result.wordCount} | ${result.meetsRequirements ? "Đạt yêu cầu" : "Chưa đạt"}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStrengths() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          ' Điểm mạnh:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...result.strengths.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(s)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildImprovements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          ' Cần cải thiện:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...result.improvements.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.arrow_forward, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(s)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildGrammarErrors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          ' Lỗi ngữ pháp:',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        const SizedBox(height: 8),
        ...result.grammarErrors.map((error) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.close, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      error.error,
                      style: const TextStyle(
                        color: Colors.red,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.check, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      error.correction,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      error.explanation,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildVocabularySuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          ' Gợi ý từ vựng:',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 8),
        ...result.vocabularySuggestions.map((sug) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Text đầu có thể cuộn ngang
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        '"${sug.word}"',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        softWrap: false, // không xuống dòng
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 16),
                  const SizedBox(width: 8),

                  // Text sau có thể cuộn ngang
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        '"${sug.better}"',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                        softWrap: false,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),
              Text(
                sug.context,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}