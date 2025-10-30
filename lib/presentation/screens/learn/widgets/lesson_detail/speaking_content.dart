import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
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
  late stt.SpeechToText _speech;
  late AIService _aiService;

  bool _speechInitialized = false;
  bool _checkingPermission = false;
  bool _isListening = false;
  bool _isCheckingSpeaking = false;

  String _spokenText = '';
  String? _errorMessage;
  SpeakingResult? _speakingResult;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _aiService = AIService.create(
      providerType: AIProviderType.gemini,
      apiKey: 'AIzaSyBl_JBlqSWCh5QcwrnNKW5SjR4sw6InMOM',
      timeout: const Duration(seconds: 30),
      maxRetries: 2,
    );
    _initializeSpeech();
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    setState(() {
      _checkingPermission = true;
      _errorMessage = null;
    });

    try {
      if (!await _requestMicrophonePermission()) {
        _setError('Quyền micro bị từ chối');
        return;
      }

      if (!await _speech.hasPermission) {
        _setError('Thiết bị thiếu Google Speech Services');
        _showGoogleAppInstallDialog();
        return;
      }

      final available = await _speech.initialize(
        onStatus: _handleSpeechStatus,
        onError: _handleSpeechError,
        debugLogging: true,
      );

      setState(() {
        _speechInitialized = available;
        _checkingPermission = false;
        if (!available) _errorMessage = 'Không thể khởi tạo Speech Recognition';
      });

      if (!available && mounted) _showDetailedError();
    } catch (e) {
      _setError(e.toString());
      if (mounted) {
        if (e.toString().contains('recognizerNotAvailable')) {
          _showGoogleAppInstallDialog();
        } else {
          _showDetailedError();
        }
      }
    }
  }

  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    return (await Permission.microphone.request()).isGranted;
  }

  void _handleSpeechStatus(String status) {
    if (status == 'notListening' || status == 'done') {
      setState(() => _isListening = false);
    }
  }

  void _handleSpeechError(dynamic error) {
    setState(() {
      _isListening = false;
      _errorMessage = 'Lỗi: ${error.errorMsg}';
    });
  }

  void _setError(String message) {
    setState(() {
      _speechInitialized = false;
      _checkingPermission = false;
      _errorMessage = message;
    });
  }

  Future<void> _startListening() async {
    if (!_speechInitialized || _isListening || _checkingPermission) return;

    if (!(await Permission.microphone.status).isGranted) {
      _showError('Vui lòng cấp quyền micro để ghi âm');
      return;
    }

    setState(() => _isListening = true);

    try {
      await _speech.listen(
        onResult: (result) => setState(() => _spokenText = result.recognizedWords),
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        localeId: 'vi-VN',
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      setState(() => _isListening = false);
      _showError('Lỗi khởi động micro: $e');
    }
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    await _speech.stop();
    setState(() => _isListening = false);
  }


  Future<void> _checkSpeakingWithAI() async {
    if (_spokenText.trim().isEmpty) {
      _showError('Vui lòng ghi âm trước khi chấm điểm');
      return;
    }

    setState(() => _isCheckingSpeaking = true);

    try {
      final content = widget.lesson.content;
      final words = (content['words'] as List? ?? []).map((w) => w.toString()).toList();
      final sentences = content['sentences'] as List? ?? [];
      final expectedContent = sentences.isNotEmpty ? sentences.join(' ') : words.join(' ');

      final result = await _aiService.checkSpeaking(
        transcript: _spokenText,
        expectedContent: expectedContent,
        targetWords: words,
      );

      setState(() {
        _speakingResult = result;
        _isCheckingSpeaking = false;
      });

      if (!result.hasError && mounted) {
        _showSuccess('🎉 Điểm: ${result.score}/100 - ${_getScoreFeedback(result.score)}');
      }
    } catch (e) {
      setState(() => _isCheckingSpeaking = false);
      _showError('Lỗi chấm điểm: $e');
    }
  }

  String _getScoreFeedback(int score) {
    if (score >= 90) return 'Xuất sắc!';
    if (score >= 80) return 'Rất tốt!';
    if (score >= 70) return 'Tốt!';
    if (score >= 60) return 'Khá';
    return 'Cần luyện tập thêm';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
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
          const SizedBox(height: 14),
          _buildMicrophone(),
          const SizedBox(height: 10),
          if (!_speechInitialized) ...[
            _buildInitializationStatus(),
            const SizedBox(height: 16),
          ],
          if (_spokenText.isNotEmpty) ...[
            _buildSpokenTextCard(),
            const SizedBox(height: 16),
          ],
          if (_speakingResult != null && !_speakingResult!.hasError) ...[
            SpeakingResultCard(result: _speakingResult!),
            const SizedBox(height: 24),
          ],
          if (words.isNotEmpty) ...[
            _buildWordsSection(words),
            const SizedBox(height: 24),
          ],
          if (vocabulary.isNotEmpty) ...[
            _buildVocabularySection(vocabulary),
            const SizedBox(height: 24),
          ],
          if (sentences.isNotEmpty) ...[
            _buildSentencesSection(sentences),
            const SizedBox(height: 12),
          ],
          CompleteButton(
            lesson: widget.lesson,
            startTime: widget.startTime,
            customScore: _speakingResult?.score,
          ),
        ],
      ),
    );
  }

  Widget _buildMicrophone() {
    return Center(
      child: Column(
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
                  colors: _getMicrophoneGradient(),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getMicrophoneShadowColor(),
                    blurRadius: 20,
                    spreadRadius: _isListening ? 10 : 5,
                  ),
                ],
              ),
              child: Icon(
                _getMicrophoneIcon(),
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getMicrophoneText(),
            style: TextStyle(
              fontSize: 16,
              color: _getMicrophoneTextColor(),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
          ],
          if (!_speechInitialized) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  icon: Icons.refresh,
                  label: 'Thử lại',
                  color: Colors.orange,
                  onPressed: _initializeSpeech,
                ),
                _buildActionButton(
                  icon: Icons.settings,
                  label: 'Cài đặt',
                  color: Colors.blue,
                  onPressed: openAppSettings,
                ),
                _buildActionButton(
                  icon: Icons.help_outline,
                  label: 'Hướng dẫn',
                  color: Colors.green,
                  onPressed: _showGoogleAppInstallDialog,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Color> _getMicrophoneGradient() {
    if (_checkingPermission) return [Colors.blue.shade400, Colors.blue.shade600];
    if (_isListening) return [Colors.red.shade600, Colors.red.shade800];
    if (!_speechInitialized) return [Colors.grey.shade400, Colors.grey.shade600];
    return [Colors.red.shade400, Colors.orange.shade600];
  }

  Color _getMicrophoneShadowColor() {
    if (_checkingPermission) return Colors.blue.withOpacity(0.6);
    if (_isListening) return Colors.red.withOpacity(0.6);
    if (!_speechInitialized) return Colors.grey.withOpacity(0.3);
    return Colors.red.withOpacity(0.3);
  }

  IconData _getMicrophoneIcon() {
    if (_checkingPermission) return Icons.pending;
    if (_isListening) return Icons.mic;
    if (!_speechInitialized) return Icons.mic_off;
    return Icons.mic_none;
  }

  String _getMicrophoneText() {
    if (_checkingPermission) return 'Đang kiểm tra...';
    if (!_speechInitialized) return 'Speech Recognition không khả dụng';
    if (_isListening) return 'Đang nghe... Nói gì đó!';
    return 'Chạm và giữ để nói';
  }

  Color _getMicrophoneTextColor() {
    if (_checkingPermission) return Colors.blue.shade700;
    if (!_speechInitialized) return Colors.red.shade700;
    return Colors.grey.shade700;
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: _checkingPermission ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(backgroundColor: color),
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
          const Row(
            children: [
              Icon(Icons.info, color: Colors.orange),
              SizedBox(width: 12),
              Text('Speech Recognition chưa sẵn sàng', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Để sử dụng tính năng ghi âm, vui lòng:', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          ...[
            'Cài đặt Google app từ Play Store',
            'Cấp quyền micro cho ứng dụng',
            'Đảm bảo có kết nối internet',
            'Sử dụng thiết bị thực (không dùng emulator)',
          ].map((text) => Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('• $text', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          )),
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
              const Text('🎤 Bạn đã nói:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _startListening,
                    tooltip: 'Ghi âm lại',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() {
                      _spokenText = '';
                      _speakingResult = null;
                    }),
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
            child: Text(_spokenText, style: const TextStyle(fontSize: 16, height: 1.4)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCheckingSpeaking ? null : _checkSpeakingWithAI,
              icon: _isCheckingSpeaking
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isCheckingSpeaking ? 'AI đang chấm điểm...' : 'CHẤM ĐIỂM VỚI AI'),
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
        const Text('🗣️ Từ vựng cần luyện', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: words.map((word) {
            final isDetected = _speakingResult?.detectedWords.contains(word) ?? false;
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
        const Text('📚 Từ vựng mở rộng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...vocabulary.map((word) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.record_voice_over, color: Colors.orange),
            title: Text(word.toString()),
            trailing: IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: () {},
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildSentencesSection(List sentences) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('💬 Câu mẫu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...sentences.map((sentence) => Container(
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
              Expanded(child: Text(sentence.toString(), style: const TextStyle(fontSize: 16))),
            ],
          ),
        )),
      ],
    );
  }

  void _showGoogleAppInstallDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Expanded(child: Text('Google Speech Services không khả dụng')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thiết bị của bạn thiếu Google Speech Recognition Service.', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            const Text('Để sử dụng tính năng này, bạn cần:'),
            const SizedBox(height: 8),
            ...[
              'Cài đặt/cập nhật Google app từ Play Store',
              'Đảm bảo Google Play Services hoạt động',
              'Kiểm tra kết nối internet',
              'Khởi động lại ứng dụng sau khi cài',
            ].map(_buildBulletPoint),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Emulator thường không có Google Services. Vui lòng test trên thiết bị thực.', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showDetailedError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Không thể khởi tạo nhận dạng giọng nói'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade900)),
              ),
              const SizedBox(height: 16),
            ],
            const Text('Nguyên nhân có thể:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...[
              'Thiếu Google Speech Services',
              'Quyền micro chưa được cấp',
              'Thiết bị không hỗ trợ',
              'Không có kết nối internet',
            ].map(_buildBulletPoint),
            const SizedBox(height: 12),
            const Text('Vui lòng thử:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...[
              'Chạy trên thiết bị thực (không phải emulator)',
              'Cài đặt Google app từ Play Store',
              'Cấp quyền micro trong cài đặt',
              'Kiểm tra internet và khởi động lại app',
            ].map(_buildBulletPoint),
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
              _initializeSpeech();
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}