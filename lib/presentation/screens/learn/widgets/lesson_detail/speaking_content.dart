import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../../data/datasources/remote/ai/ai_service.dart';
import '../../../../../data/datasources/remote/ai/models/speaking_result.dart';
import '../../../../../data/datasources/remote/ai/providers/ai_provider.dart';
import '../../../../../data/models/lesson_model.dart';
import './shared/lesson_header.dart';
import './shared/complete_button.dart';
import 'ai_results/speaking_result_card.dart';

class SpeakingContent extends StatefulWidget {
  final LessonModel lesson;
  final DateTime startTime;

  const SpeakingContent({
    super.key,
    required this.lesson,
    required this.startTime,
  });

  @override
  State<SpeakingContent> createState() => _SpeakingContentState();
}

class _SpeakingContentState extends State<SpeakingContent> {
  late stt.SpeechToText speech;
  late AIService aiService;
  bool _speechInitialized = false;
  bool _checkingPermission = false;

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();

    // Sử dụng factory constructor
    aiService = AIService.create(
      providerType: AIProviderType.gemini,
      apiKey: 'AIzaSyBl_JBlqSWCh5QcwrnNKW5SjR4sw6InMOM',
      timeout: const Duration(seconds: 30),
      maxRetries: 2,
    );

    // Khởi tạo speech recognition sớm
    _initializeSpeech();
  }

  bool isListening = false;
  String spokenText = '';
  bool isCheckingSpeaking = false;
  SpeakingResult? speakingResult;

  Future<void> _initializeSpeech() async {
    try {
      print('🔄 Bắt đầu khởi tạo speech recognition...');

      // Kiểm tra quyền trước khi khởi tạo
      final micPermission = await Permission.microphone.status;
      print('🎤 Trạng thái quyền micro: $micPermission');

      if (!micPermission.isGranted) {
        setState(() => _checkingPermission = true);
        final requested = await Permission.microphone.request();
        print('🎤 Kết quả yêu cầu quyền: $requested');
        setState(() => _checkingPermission = false);

        if (!requested.isGranted) {
          setState(() => _speechInitialized = false);
          _showError('Quyền micro bị từ chối. Vui lòng cấp quyền trong cài đặt.');
          return;
        }
      }

      bool available = await speech.initialize(
        onStatus: (status) {
          print('📢 Trạng thái speech: $status');
          if (status == 'notListening' && isListening) {
            setState(() => isListening = false);
          } else if (status == 'done') {
            setState(() => isListening = false);
          }
        },
        onError: (error) {
          print('❌ Lỗi speech: $error');
          setState(() => isListening = false);
          if (mounted) {
            _showError('Lỗi nhận dạng giọng nói: $error');
          }
        },
      );

      print('✅ Kết quả khởi tạo speech: $available');

      setState(() {
        _speechInitialized = available;
      });

      if (!available && mounted) {
        _showDetailedError();
      }
    } catch (e) {
      print('💥 Lỗi khởi tạo speech: $e');
      setState(() => _speechInitialized = false);
      if (mounted) {
        _showError('Lỗi khởi tạo micro: $e');
      }
    }
  }

  void _showDetailedError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Không thể khởi tạo nhận dạng giọng nói'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nguyên nhân có thể:'),
            SizedBox(height: 8),
            Text('• Quyền micro chưa được cấp'),
            Text('• Thiết bị không hỗ trợ'),
            Text('• Thiếu Google Speech Services'),
            Text('• Không có kết nối internet'),
            SizedBox(height: 12),
            Text('Vui lòng thử:'),
            Text('• Chạy trên thiết bị thực'),
            Text('• Cấp quyền micro'),
            Text('• Kiểm tra internet'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Cài đặt'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.lesson.content;
    final words = content['words'] as List? ?? [];
    final sentences = content['sentences'] as List? ?? [];
    final vocabulary = content['vocabulary'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LessonHeader(lesson: widget.lesson),
          const SizedBox(height: 24),

          // Microphone with Speech-to-Text
          _buildMicrophone(),
          const SizedBox(height: 24),

          // Hiển thị trạng thái khởi tạo
          if (!_speechInitialized) ...[
            _buildInitializationStatus(),
            const SizedBox(height: 16),
          ],

          // Spoken Text Display
          if (spokenText.isNotEmpty) ...[
            _buildSpokenTextCard(),
            const SizedBox(height: 16),
          ],

          // AI Speaking Result
          if (speakingResult != null && !speakingResult!.hasError) ...[
            SpeakingResultCard(result: speakingResult!),
            const SizedBox(height: 24),
          ],

          // Words to Practice
          if (words.isNotEmpty) ...[
            _buildWordsSection(words),
            const SizedBox(height: 24),
          ],

          // Vocabulary List
          if (vocabulary.isNotEmpty) ...[
            _buildVocabularySection(vocabulary),
            const SizedBox(height: 24),
          ],

          // Example Sentences
          if (sentences.isNotEmpty) ...[
            _buildSentencesSection(sentences),
            const SizedBox(height: 24),
          ],

          CompleteButton(
            lesson: widget.lesson,
            startTime: widget.startTime,
            customScore: speakingResult?.score,
          ),
        ],
      ),
    );
  }

  Widget _buildMicrophone() {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTapDown: (_) => _startListening(),
                onTapUp: (_) => _stopListening(),
                onTapCancel: _stopListening,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _checkingPermission
                          ? [Colors.blue.shade400, Colors.blue.shade600]
                          : isListening
                          ? [Colors.red.shade600, Colors.red.shade800]
                          : !_speechInitialized
                          ? [Colors.grey.shade400, Colors.grey.shade600]
                          : [Colors.red.shade400, Colors.orange.shade600],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _checkingPermission
                            ? Colors.blue.withOpacity(0.6)
                            : isListening
                            ? Colors.red.withOpacity(0.6)
                            : !_speechInitialized
                            ? Colors.grey.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: isListening ? 10 : 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _checkingPermission
                        ? Icons.pending
                        : isListening
                        ? Icons.mic
                        : !_speechInitialized
                        ? Icons.mic_off
                        : Icons.mic_none,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_checkingPermission)
                const Positioned(
                  top: 10,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _checkingPermission
                ? '⏳ Đang kiểm tra quyền...'
                : !_speechInitialized
                ? '❌ Micro chưa sẵn sàng'
                : isListening
                ? '🎤 Đang nghe... Nói gì đó!'
                : '👆 Chạm và giữ để nói',
            style: TextStyle(
              fontSize: 16,
              color: _checkingPermission
                  ? Colors.blue.shade700
                  : !_speechInitialized
                  ? Colors.red.shade700
                  : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (!_speechInitialized) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _checkingPermission ? null : _initializeSpeech,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _checkingPermission ? null : _openAppSettings,
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('Cài đặt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInitializationStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info, color: Colors.orange),
              const SizedBox(width: 12),
              const Text(
                'Micro chưa sẵn sàng',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Để sử dụng tính năng ghi âm, vui lòng:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text('• Cấp quyền micro cho ứng dụng', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          Text('• Đảm bảo có kết nối internet', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          Text('• Sử dụng thiết bị thực (không dùng giả lập)', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildSpokenTextCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🎤 Bạn đã nói:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  if (spokenText.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: _startListening,
                      tooltip: 'Ghi âm lại',
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        spokenText = '';
                        speakingResult = null;
                      });
                    },
                    tooltip: 'Xóa',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Text(
              spokenText,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isCheckingSpeaking ? null : _checkSpeakingWithAI,
              icon: isCheckingSpeaking
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.auto_awesome),
              label: Text(isCheckingSpeaking ? 'AI đang chấm điểm...' : 'CHẤM ĐIỂM VỚI AI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordsSection(List words) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🗣️ Từ vựng cần luyện',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: words.map((word) {
            final isDetected = speakingResult?.detectedWords.contains(word) ?? false;
            return Chip(
              label: Text(word.toString()),
              avatar: Icon(
                isDetected ? Icons.check_circle : Icons.volume_up,
                size: 18,
                color: isDetected ? Colors.green : null,
              ),
              backgroundColor: isDetected ? Colors.green.shade50 : Colors.orange.shade50,
              side: BorderSide(color: isDetected ? Colors.green.shade300 : Colors.orange.shade300),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVocabularySection(List vocabulary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📚 Từ vựng mở rộng',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...vocabulary.map((word) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.record_voice_over, color: Colors.orange),
              title: Text(word.toString()),
              trailing: IconButton(
                icon: const Icon(Icons.volume_up),
                onPressed: () {
                  // TODO: Play audio
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSentencesSection(List sentences) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💬 Câu mẫu',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...sentences.map((sentence) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(sentence.toString(), style: const TextStyle(fontSize: 16)),
                ),
                IconButton(
                  icon: const Icon(Icons.play_circle_outline),
                  onPressed: () {
                    // TODO: Play audio
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<void> _startListening() async {
    if (!_speechInitialized || isListening || _checkingPermission) return;

    try {
      // Kiểm tra quyền lần cuối trước khi bắt đầu
      final micPermission = await Permission.microphone.status;
      if (!micPermission.isGranted) {
        _showError('Vui lòng cấp quyền micro để ghi âm');
        return;
      }

      setState(() => isListening = true);

      await speech.listen(
        onResult: (result) {
          setState(() {
            spokenText = result.recognizedWords;
          });
          print('🎙️ Nhận dạng: ${result.recognizedWords}');
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'vi-VN',
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
        onSoundLevelChange: (level) {
          // Có thể thêm hiệu ứng âm thanh ở đây
        },
      );

    } catch (e) {
      print('❌ Lỗi khi bắt đầu ghi âm: $e');
      setState(() => isListening = false);
      _showError('Lỗi khởi động micro: $e');
    }
  }

  Future<void> _stopListening() async {
    if (!isListening) return;

    try {
      await speech.stop();
      setState(() => isListening = false);
      print('⏹️ Đã dừng ghi âm');
    } catch (e) {
      print('❌ Lỗi khi dừng ghi âm: $e');
      setState(() => isListening = false);
    }
  }

  Future<void> _checkSpeakingWithAI() async {
    if (spokenText.trim().isEmpty) {
      _showError('Vui lòng ghi âm trước khi chấm điểm');
      return;
    }

    setState(() => isCheckingSpeaking = true);

    try {
      final content = widget.lesson.content;
      final words = content['words'] as List? ?? [];
      final sentences = content['sentences'] as List? ?? [];

      final expectedContent = sentences.isNotEmpty ? sentences.join(' ') : words.join(' ');

      final result = await aiService.checkSpeaking(
        transcript: spokenText,
        expectedContent: expectedContent,
        targetWords: words.map((w) => w.toString()).toList(),
      );

      setState(() {
        speakingResult = result;
        isCheckingSpeaking = false;
      });

      if (!result.hasError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Điểm: ${result.score}/100 - ${_getScoreFeedback(result.score)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Lỗi khi chấm điểm AI: $e');
      setState(() => isCheckingSpeaking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chấm điểm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getScoreFeedback(int score) {
    if (score >= 90) return 'Xuất sắc!';
    if (score >= 80) return 'Rất tốt!';
    if (score >= 70) return 'Tốt!';
    if (score >= 60) return 'Khá';
    return 'Cần luyện tập thêm';
  }

  Future<void> _openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      _showError('Không thể mở cài đặt: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    speech.stop();
    super.dispose();
  }
}