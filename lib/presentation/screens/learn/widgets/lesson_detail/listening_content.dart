import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../../../data/models/lesson_model.dart';
import './shared/lesson_header.dart';
import './shared/question_list.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ListeningContent extends StatefulWidget {
  final LessonModel lesson;
  final DateTime startTime;

  const ListeningContent({
    super.key,
    required this.lesson,
    required this.startTime,
  });

  @override
  State<ListeningContent> createState() => _ListeningContentState();
}

class _ListeningContentState extends State<ListeningContent> {
  FlutterTts? _flutterTts;
  bool _isPlaying = false;
  double _speechRate = 0.5;
  final Map<String, double> _speedOptions = {
    'Rất chậm': 0.3,
    'Chậm': 0.5,
    'Bình thường': 0.7,
    'Nhanh': 1.0,
    'Rất nhanh': 1.3,
  };

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void dispose() {
    _flutterTts?.stop();
    _flutterTts = null;
    super.dispose();
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();

    _flutterTts!.setStartHandler(() {
      if (mounted) setState(() => _isPlaying = true);
    });
    _flutterTts!.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });
    _flutterTts!.setCancelHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });
    _flutterTts!.setErrorHandler((msg) {
      if (mounted) setState(() => _isPlaying = false);
    });

    await _flutterTts!.setLanguage('en-US');
    await _flutterTts!.setSpeechRate(_speechRate);
    await _flutterTts!.setVolume(1.0);
    await _flutterTts!.setPitch(1.0);
    await _flutterTts!.awaitSpeakCompletion(true);
  }

  Future<void> _changeSpeechRate(double newRate) async {
    _speechRate = newRate;
    await _flutterTts?.setSpeechRate(newRate);
  }

  void _showSpeedMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chọn tốc độ đọc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._speedOptions.entries.map((entry) {
              final isSelected = _speechRate == entry.value;
              return ListTile(
                leading: Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? Colors.blue : Colors.grey),
                title: Text(entry.key, style: TextStyle(color: isSelected ? Colors.blue : Colors.black)),
                trailing: Text('${entry.value}x', style: TextStyle(color: isSelected ? Colors.blue : Colors.grey)),
                onTap: () {
                  _changeSpeechRate(entry.value);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSpeech(String transcript) async {
    if (transcript.isEmpty) return;

    try {
      await _flutterTts!.setLanguage('en-US');

      if (_isPlaying) {
        await _flutterTts!.stop();
        setState(() => _isPlaying = false);
      } else {
        await _flutterTts!.speak(transcript);
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.lesson.content;
    final transcript = content['transcript'] ?? '';
    final questions = content['questions'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LessonHeader(lesson: widget.lesson),
          const SizedBox(height: 14),
          _buildTtsPlayer(transcript),
          const SizedBox(height: 10),
          _buildTranscript(transcript),
          const SizedBox(height: 10),
          if (questions.isNotEmpty)
            QuestionList(
              questions: questions,
              lesson: widget.lesson,
              startTime: widget.startTime,
            ),
        ],
      ),
    );
  }

  Widget _buildTtsPlayer(String transcript) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  onTap: _showSpeedMenu,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.speed, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '${_speechRate}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Colors.white, size: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            size: 50,
            color: Colors.white,
          ),
          const SizedBox(height: 6),
          Text(
            _isPlaying ? 'Đang đọc transcript...' : 'Nhấn để nghe transcript',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _toggleSpeech(transcript),
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              label: Text(_isPlaying ? 'Tạm dừng' : 'Đọc transcript'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscript(String transcript) {
    return ExpansionTile(
      title: const Text('Xem Transcript'),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
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