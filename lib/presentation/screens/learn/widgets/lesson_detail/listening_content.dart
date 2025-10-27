import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../../data/models/lesson_model.dart';
import './shared/lesson_header.dart';
import './shared/question_list.dart';

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
  bool _isInitializing = false;
  int _initRetryCount = 0;
  static const int _maxRetries = 2;

  double _speechRate = 0.5;
  final Map<String, double> _speedOptions = {
    'Rất chậm': 0.3,
    'Chậm': 0.5,
    'Bình thường': 0.7,
    'Nhanh': 1.0,
    'Rất nhanh': 1.3,
  };

  @override
  void dispose() {
    _flutterTts?.stop();
    _flutterTts = null;
    super.dispose();
  }

  Future<bool> _ensureTtsInitialized({bool retry = false}) async {
    if (_flutterTts != null && _initRetryCount < _maxRetries) return true;

    if (_isInitializing) {
      _showMessage('Đang khởi tạo TTS, vui lòng đợi...');
      return false;
    }

    setState(() => _isInitializing = true);

    try {
      print(' Initializing TTS (retry: $retry)...');

      if (retry && _flutterTts != null) {
        await _flutterTts!.stop();
        _flutterTts = null;
      }

      _flutterTts = FlutterTts();
      _initRetryCount = 0;

      _flutterTts!.setStartHandler(() {
        print(' TTS Started');
        if (mounted) setState(() => _isPlaying = true);
      });

      _flutterTts!.setCompletionHandler(() {
        print(' TTS Completed');
        if (mounted) setState(() => _isPlaying = false);
      });

      _flutterTts!.setCancelHandler(() {
        print(' TTS Cancelled');
        if (mounted) setState(() => _isPlaying = false);
      });

      _flutterTts!.setErrorHandler((msg) {
        print(' TTS Error: $msg');
        if (mounted) setState(() => _isPlaying = false);
        if (msg.contains('not bound') || msg.contains('isLanguageAvailable failed')) {
          _initRetryCount++;
          _showMessage('TTS chưa bind. Thử lại (lần ${_initRetryCount}/$_maxRetries)');
        } else {
          _showMessage('Lỗi TTS: $msg');
        }
      });

      final engines = await _flutterTts!.getEngines;
      print(' Available TTS engines: ${engines.length}');
      if (engines.isEmpty) {
        throw Exception('No TTS engine installed. Install Google TTS from Play Store.');
      }

      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setSpeechRate(_speechRate);
      await _flutterTts!.setPitch(1.0);
      await _flutterTts!.awaitSpeakCompletion(true);

      print(' TTS initialized successfully');
      if (mounted) setState(() => _isInitializing = false);
      return true;
    } catch (e) {
      print(' TTS init failed: $e');
      _initRetryCount++;
      if (mounted) {
        setState(() => _isInitializing = false);
        _showMessage('Khởi tạo TTS fail: $e. Thử lại? (Lần ${_initRetryCount}/$_maxRetries)');
      }
      if (_initRetryCount < _maxRetries && retry) {
        await Future.delayed(const Duration(seconds: 1));
        return await _ensureTtsInitialized(retry: true);
      }
      return false;
    }
  }

  Future<void> _changeSpeechRate(double newRate) async {
    setState(() => _speechRate = newRate);

    if (_flutterTts != null) {
      await _flutterTts!.setSpeechRate(newRate);
      print('🎚 Speech rate changed to: $newRate');
      _showMessage('Đã thay đổi tốc độ đọc');
    }
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
            const Text(
              ' Chọn tốc độ đọc',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._speedOptions.entries.map((entry) {
              final isSelected = _speechRate == entry.value;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? Colors.blue : Colors.grey,
                ),
                title: Text(
                  entry.key,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blue : Colors.black,
                  ),
                ),
                trailing: Text(
                  '${entry.value}x',
                  style: TextStyle(
                    color: isSelected ? Colors.blue : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
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
    if (transcript.isEmpty) {
      _showMessage('Không có nội dung để đọc');
      return;
    }

    final ready = await _ensureTtsInitialized(retry: true);
    if (!ready) return;

    try {
      await _flutterTts!.setLanguage('en-US');

      if (_isPlaying) {
        print(' Stopping TTS...');
        await _flutterTts!.stop();
        if (mounted) setState(() => _isPlaying = false);
      } else {
        print(' Speaking: ${transcript.substring(0, transcript.length > 50 ? 50 : transcript.length)}...');

        final result = await _flutterTts!.speak(transcript);
        print(' Speak initiated with result: $result');
        if (result != 1) {
          _showMessage('Speak failed (code: $result). Check TTS engine.');
        }
      }
    } catch (e) {
      print(' Speech error: $e');
      if (mounted) {
        setState(() => _isPlaying = false);
        _showMessage('Lỗi phát âm: $e');
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Thử lại',
            onPressed: () {
              _initRetryCount = 0;
              _toggleSpeech(widget.lesson.content['transcript'] ?? '');
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.lesson.content;
    final transcript = content['transcript'] ?? '';
    final questions = content['questions'] as List? ?? [];

    final isDisabled = _isInitializing || transcript.isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LessonHeader(lesson: widget.lesson),
          const SizedBox(height: 14),

          // Audio Player
          _buildTtsPlayer(transcript, isDisabled),
          const SizedBox(height: 10),

          // Transcript
          _buildTranscript(transcript),
          const SizedBox(height: 10),

          // Questions
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

  Widget _buildTtsPlayer(String transcript, bool isDisabled) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDisabled
              ? [Colors.grey.shade400, Colors.grey.shade600]
              : [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Speed control button
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
                      const Icon(
                        Icons.speed,
                        color: Colors.white,
                        size: 14,
                      ),
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
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                        size: 12,
                      ),
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
            _isPlaying
                ? ' Đang đọc transcript...'
                : _isInitializing
                ? ' Đang khởi tạo TTS...'
                : transcript.isEmpty
                ? ' Không có transcript'
                : ' Nhấn để nghe transcript',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isDisabled ? null : () => _toggleSpeech(transcript),
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              label: Text(_isPlaying ? 'TẠM DỪNG' : 'ĐỌC TRANSCRIPT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade600,
                disabledBackgroundColor: Colors.white54,
                disabledForegroundColor: Colors.blue.shade300,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          if (isDisabled && !_isPlaying) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _ensureTtsInitialized(retry: true),
              child: const Text('Khởi tạo lại', style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTranscript(String transcript) {
    return ExpansionTile(
      title: const Text(' Xem Transcript'),
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