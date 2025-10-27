import 'package:flutter/material.dart';
import 'package:learn_english/presentation/screens/learn/widgets/lesson_detail/ai_results/score_result.dart';
import '../../../../../../data/datasources/remote/ai/models/speaking_result.dart';

class SpeakingResultCard extends StatelessWidget {
  final SpeakingResult result;

  const SpeakingResultCard({
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
            if (result.strengths.isNotEmpty) ...[
              _buildStrengths(),
              const SizedBox(height: 12),
            ],
            if (result.improvements.isNotEmpty) ...[
              _buildImprovements(),
              const SizedBox(height: 12),
            ],
            if (result.missingWords.isNotEmpty) _buildMissingWords(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Icon(Icons.stars, color: Colors.orange, size: 28),
        SizedBox(width: 12),
        Text(
          'Kết quả AI',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildScores() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ScoreCircle(label: 'Tổng', score: result.score, color: Colors.blue),
        ScoreCircle(label: 'Phát âm', score: result.pronunciationScore, color: Colors.orange),
        ScoreCircle(label: 'Lưu loát', score: result.fluencyScore, color: Colors.green),
        ScoreCircle(label: 'Chính xác', score: result.accuracyScore, color: Colors.purple),
      ],
    );
  }

  Widget _buildFeedback() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb, color: Colors.blue),
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

  Widget _buildStrengths() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '✅ Điểm mạnh:',
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
          '💡 Cần cải thiện:',
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

  Widget _buildMissingWords() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '❌ Từ chưa nói:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: result.missingWords
                .map((w) => Chip(
              label: Text(w),
              backgroundColor: Colors.red.shade100,
            ))
                .toList(),
          ),
        ],
      ),
    );
  }
}