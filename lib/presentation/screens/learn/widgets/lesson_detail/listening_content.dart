import 'package:flutter/material.dart';
import '../../../../../data/models/lesson_model.dart';
import './shared/lesson_header.dart';
import './shared/question_list.dart';

class ListeningContent extends StatelessWidget {
  final LessonModel lesson;
  final DateTime startTime;

  const ListeningContent({
    super.key,
    required this.lesson,
    required this.startTime,
  });

  @override
  Widget build(BuildContext context) {
    final content = lesson.content;
    final audioUrl = content['audioUrl'] ?? '';
    final transcript = content['transcript'] ?? '';
    final questions = content['questions'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LessonHeader(lesson: lesson),
          const SizedBox(height: 24),

          // Audio Player Section
          _buildAudioPlayer(audioUrl),
          const SizedBox(height: 24),

          // Transcript (Expandable)
          _buildTranscript(transcript),
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

  Widget _buildAudioPlayer(String audioUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.headphones, size: 64, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            audioUrl,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) => ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement audio playback
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🎵 Playing audio...')),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('PHÁT AUDIO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscript(String transcript) {
    return ExpansionTile(
      title: const Text('📝 Xem Transcript'),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            transcript,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
      ],
    );
  }
}