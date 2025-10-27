import 'package:flutter/material.dart';
//import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../../data/datasources/remote/ai/ai_service.dart';
import '../../../../../data/datasources/remote/ai/models/writing_result.dart';
import '../../../../../data/datasources/remote/ai/providers/ai_provider.dart';
import '../../../../../data/models/lesson_model.dart';
import './shared/lesson_header.dart';
import './shared/complete_button.dart';
import 'ai_results/writing_result_card.dart';

class WritingContent extends StatefulWidget {
  final LessonModel lesson;
  final DateTime startTime;
  const WritingContent({
    super.key,
    required this.lesson,
    required this.startTime,
  });

  @override
  State<WritingContent> createState() => _WritingContentState();
}

class _WritingContentState extends State<WritingContent> {
  final TextEditingController writingController = TextEditingController();
  late AIService aiService;
  bool isCheckingWriting = false;
  WritingResult? writingResult;

  @override
  void initState() {
    super.initState();

    // Sử dụng factory constructor
    aiService = AIService.create(
      providerType: AIProviderType.gemini,
      apiKey: 'AIzaSyBl_JBlqSWCh5QcwrnNKW5SjR4sw6InMOM',
      timeout: const Duration(seconds: 30),
      maxRetries: 2,
    );
  }

  @override
  void dispose() {
    writingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.lesson.content;
    final prompt = content['prompt'] ?? '';
    final template = content['template'] ?? '';
    final structure = content['structure'] as List? ?? [];
    final requirements = content['requirements'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LessonHeader(lesson: widget.lesson),
          const SizedBox(height: 24),

          // Prompt
          if (prompt.isNotEmpty) ...[
            _buildPromptBox(prompt),
            const SizedBox(height: 16),
          ],

          // Structure Guide
          if (structure.isNotEmpty) ...[
            _buildStructureSection(structure),
            const SizedBox(height: 16),
          ],

          // Requirements
          if (requirements.isNotEmpty) ...[
            _buildRequirementsSection(requirements),
            const SizedBox(height: 16),
          ],

          // Template
          if (template.isNotEmpty) ...[
            _buildTemplateSection(template),
            const SizedBox(height: 16),
          ],

          // Writing Area
          _buildWritingArea(),
          const SizedBox(height: 16),

          // Check with AI button
          _buildCheckButton(),
          const SizedBox(height: 24),

          // AI Writing Result
          if (writingResult != null && !writingResult!.hasError) ...[
            WritingResultCard(result: writingResult!),
            const SizedBox(height: 24),
          ],

          CompleteButton(
            lesson: widget.lesson,
            startTime: widget.startTime,
            customScore: writingResult?.score,
          ),
        ],
      ),
    );
  }

  Widget _buildPromptBox(String prompt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment, color: Colors.purple.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(prompt, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildStructureSection(List structure) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          ' Cấu trúc gợi ý',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...structure.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.purple.shade700,
                  child: Text(
                    '${entry.key + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value.toString(),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRequirementsSection(List requirements) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          ' Yêu cầu',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...requirements.map((req) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.purple.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(req.toString(), style: const TextStyle(fontSize: 15)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTemplateSection(String template) {
    return ExpansionTile(
      title: const Text(' Xem mẫu'),
      initiallyExpanded: false,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            template,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'monospace',
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWritingArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          ' Bài làm của bạn',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: writingController,
          maxLines: 12,
          decoration: InputDecoration(
            hintText: 'Viết bài của bạn ở đây...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            counterText: '',
          ),
          maxLength: 1000,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Số từ: ${_countWords(writingController.text)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            TextButton.icon(
              onPressed: () {
                writingController.clear();
                setState(() {
                  writingResult = null;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Làm lại'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (isCheckingWriting || writingController.text.trim().isEmpty)
            ? null
            : _checkWritingWithAI,
        icon: isCheckingWriting
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : const Icon(Icons.auto_awesome,color: Colors.white,),
        label: Text(isCheckingWriting ? 'AI đang chấm bài...' : 'CHẤM BÀI VỚI AI',style: TextStyle(
          color: Colors.white
        ),),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple[400],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  int _countWords(String text) {
    return text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  Future<void> _checkWritingWithAI() async {
    final text = writingController.text.trim();
    if (text.isEmpty) return;

    setState(() => isCheckingWriting = true);

    try {
      final content = widget.lesson.content;
      final promptText = content['prompt'] ?? '';
      final requirements = (content['requirements'] as List?)?.map((r) => r.toString()).toList() ?? [];

      final result = await aiService.checkWriting(
        text: text,
        prompt: promptText,
        requirements: requirements,
        minWords: 30,
      );

      setState(() {
        writingResult = result;
        isCheckingWriting = false;
      });

      if (!result.hasError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Điểm: ${result.score}/100'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => isCheckingWriting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}