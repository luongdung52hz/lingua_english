import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learn_english/presentation/screens/learn/widgets/lesson_detail/listening_content.dart';
import 'package:learn_english/presentation/screens/learn/widgets/lesson_detail/reading_content.dart';
import 'package:learn_english/presentation/screens/learn/widgets/lesson_detail/speaking_content.dart';
import 'package:learn_english/presentation/screens/learn/widgets/lesson_detail/writing_content.dart';
import '../../../data/models/lesson_model.dart';
import '../../controllers/lesson_controller.dart';

class LessonDetailScreen extends StatefulWidget {
  final String lessonId;

  const LessonDetailScreen({
    super.key,
    required this.lessonId,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final LearnController controller = Get.find<LearnController>();
  LessonModel? lesson;
  bool isLoading = true;
  DateTime? startTime;

  @override
  void initState() {
    super.initState();
    startTime = DateTime.now();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    final loadedLesson = await controller.loadLessonById(widget.lessonId);
    setState(() {
      lesson = loadedLesson;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đang tải...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Không tìm thấy bài học'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson!.title),
        actions: [
          Chip(
            label: Text(
              lesson!.skill.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            backgroundColor: _getSkillColor(lesson!.skill),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildContentBySkill(),
    );
  }

  /// Route đến widget tương ứng theo skill
  Widget _buildContentBySkill() {
    switch (lesson!.skill) {
      case 'listening':
        return ListeningContent(
          lesson: lesson!,
          startTime: startTime!,
        );
      case 'speaking':
        return SpeakingContent(
          lesson: lesson!,
          startTime: startTime!,
        );
      case 'reading':
        return ReadingContent(
          lesson: lesson!,
          startTime: startTime!,
        );
      case 'writing':
        return WritingContent(
          lesson: lesson!,
          startTime: startTime!,
        );
      default:
        return Center(
          child: Text('Skill "${lesson!.skill}" chưa được hỗ trợ'),
        );
    }
  }

  Color _getSkillColor(String skill) {
    switch (skill) {
      case 'listening':
        return Colors.blue;
      case 'speaking':
        return Colors.orange;
      case 'reading':
        return Colors.green;
      case 'writing':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}