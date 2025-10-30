import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/models/lesson_model.dart';
import '../../app/routes/app_router.dart';
import '../../app/routes/route_names.dart';

class AdminController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers - Basic Info
  final titleCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final topicCtrl = TextEditingController();
  final durationCtrl = TextEditingController();
  final difficultyCtrl = TextEditingController();

  // Form controllers - Listening Content
  final transcriptCtrl = TextEditingController();
  final audioUrlCtrl = TextEditingController();

  // Form controllers - Speaking Content
  final pronunciationCtrl = TextEditingController();
  final exampleSentencesCtrl = TextEditingController();

  // Form controllers - Reading Content
  final readingTextCtrl = TextEditingController();

  // Form controllers - Writing Content
  final writingPromptCtrl = TextEditingController();
  final writingRequirementsCtrl = TextEditingController();

  // Form controllers - Questions (common for all)
  final List<Map<String, TextEditingController>> questionControllers = [];

  // Reactive values
  final ValueNotifier<String> level = ValueNotifier('A1');
  final ValueNotifier<String> skill = ValueNotifier('listening');

  // Stream lessons
  Stream<QuerySnapshot> get lessonsStream =>
      _firestore.collection('lessons').snapshots();

  @override
  void dispose() {
    titleCtrl.dispose();
    descriptionCtrl.dispose();
    topicCtrl.dispose();
    durationCtrl.dispose();
    difficultyCtrl.dispose();
    transcriptCtrl.dispose();
    audioUrlCtrl.dispose();
    pronunciationCtrl.dispose();
    exampleSentencesCtrl.dispose();
    readingTextCtrl.dispose();
    writingPromptCtrl.dispose();
    writingRequirementsCtrl.dispose();
    _disposeQuestionControllers();
    level.dispose();
    skill.dispose();
    super.dispose();
  }

  void _disposeQuestionControllers() {
    for (var controllers in questionControllers) {
      controllers['question']?.dispose();
      controllers['option1']?.dispose();
      controllers['option2']?.dispose();
      controllers['option3']?.dispose();
      controllers['option4']?.dispose();
    }
    questionControllers.clear();
  }

  void _clearAllFields() {
    titleCtrl.clear();
    descriptionCtrl.clear();
    topicCtrl.clear();
    durationCtrl.text = '10';
    difficultyCtrl.text = '1';
    transcriptCtrl.clear();
    audioUrlCtrl.clear();
    pronunciationCtrl.clear();
    exampleSentencesCtrl.clear();
    readingTextCtrl.clear();
    writingPromptCtrl.clear();
    writingRequirementsCtrl.clear();
    _disposeQuestionControllers();
  }

  void _addQuestion() {
    questionControllers.add({
      'question': TextEditingController(),
      'option1': TextEditingController(),
      'option2': TextEditingController(),
      'option3': TextEditingController(),
      'option4': TextEditingController(),
      'correctIndex': TextEditingController(text: '0'),
    });
    notifyListeners();
  }

  void _removeQuestion(int index) {
    final controllers = questionControllers[index];
    controllers['question']?.dispose();
    controllers['option1']?.dispose();
    controllers['option2']?.dispose();
    controllers['option3']?.dispose();
    controllers['option4']?.dispose();
    controllers['correctIndex']?.dispose();
    questionControllers.removeAt(index);
    notifyListeners();
  }

  // ⭐ Thêm cho kIsWeb

  Future<void> showAddDialog(BuildContext context) async {
    print('=== showAddDialog called ===');
    _clearAllFields();
    level.value = 'A1';
    skill.value = 'listening';

    final formKey = GlobalKey<FormState>();

    // ⭐ Sửa: Tính size dynamic dựa trên platform/screen
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWeb = kIsWeb; // Check web
    final dialogWidth = isWeb
        ? screenWidth * 0.8 // Web: 80% width (lớn hơn)
        : screenWidth * 0.9; // Mobile: 90% width
    final maxHeight = screenHeight * 0.8; // Max 80% height tránh overflow

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:  RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          insetPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          content: SizedBox(
            width: dialogWidth,
            height: maxHeight,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header (fixed height 60)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    color: Colors.blue[600], // Màu header
                    child: Row(
                      children: [
                        const Icon(Icons.add, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Thêm Bài Học',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  // Form content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildBasicInfoFields(),
                          const Divider(height: 32),
                          ValueListenableBuilder<String>(
                            valueListenable: skill,
                            builder: (context, currentSkill, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nội dung ${currentSkill.toUpperCase()}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildContentFieldsBySkill(currentSkill, setState),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Actions (fixed height 60)
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => uploadLesson(context, formKey),
                            child: const Text('Thêm'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoFields() {
    return Column(
      children: [
        TextFormField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Tiêu đề *',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
          value?.isEmpty ?? true ? 'Bắt buộc nhập tiêu đề' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: descriptionCtrl,
          decoration: const InputDecoration(
            labelText: 'Mô tả',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: topicCtrl,
          decoration: const InputDecoration(
            labelText: 'Topic *',
            border: OutlineInputBorder(),
            hintText: 'VD: Greetings & Introductions',
          ),
          validator: (value) =>
          value?.isEmpty ?? true ? 'Bắt buộc nhập topic' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: durationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Thời lượng (phút)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: difficultyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Độ khó (1-5)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<String>(
          valueListenable: level,
          builder: (context, currentLevel, _) => DropdownButtonFormField<String>(
            value: currentLevel,
            decoration: const InputDecoration(
              labelText: 'Level',
              border: OutlineInputBorder(),
            ),
            items: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                .toList(),
            onChanged: (value) {
              if (value != null) level.value = value;
            },
          ),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<String>(
          valueListenable: skill,
          builder: (context, currentSkill, _) => DropdownButtonFormField<String>(
            value: currentSkill,
            decoration: const InputDecoration(
              labelText: 'Skill',
              border: OutlineInputBorder(),
            ),
            items: ['listening', 'speaking', 'reading', 'writing']
                .map((s) => DropdownMenuItem(
              value: s,
              child: Text(s.toUpperCase()),
            ))
                .toList(),
            onChanged: (value) {
              if (value != null) skill.value = value;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContentFieldsBySkill(String currentSkill, StateSetter setState) {
    switch (currentSkill) {
      case 'listening':
        return _buildListeningFields(setState);
      case 'speaking':
        return _buildSpeakingFields(setState);
      case 'reading':
        return _buildReadingFields(setState);
      case 'writing':
        return _buildWritingFields(setState);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildListeningFields(StateSetter setState) {
    return Column(
      children: [
        TextFormField(
          controller: transcriptCtrl,
          decoration: const InputDecoration(
            labelText: 'Transcript (Nội dung nghe) *',
            border: OutlineInputBorder(),
            hintText: 'Nhập nội dung bài nghe...',
          ),
          maxLines: 5,
          validator: (value) =>
          value?.isEmpty ?? true ? 'Bắt buộc nhập transcript' : null,
        ),
        const SizedBox(height: 12),
        _buildQuestionsSection(setState),
      ],
    );
  }

  Widget _buildSpeakingFields(StateSetter setState) {
    return Column(
      children: [
        TextFormField(
          controller: pronunciationCtrl,
          decoration: const InputDecoration(
            labelText: 'Phát âm / Từ vựng *',
            border: OutlineInputBorder(),
            hintText: 'Nhập các từ cần luyện, cách dòng\nVD: cat, dog, bird',
          ),
          maxLines: 5,
          validator: (value) =>
          value?.isEmpty ?? true ? 'Bắt buộc nhập từ vựng' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: exampleSentencesCtrl,
          decoration: const InputDecoration(
            labelText: 'Câu mẫu',
            border: OutlineInputBorder(),
            hintText: 'Nhập các câu mẫu, cách dòng\nVD: My name is...',
          ),
          maxLines: 5,
        ),
        const SizedBox(height: 16),
        const Text(
          'Speaking không cần câu hỏi trắc nghiệm',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildReadingFields(StateSetter setState) {
    return Column(
      children: [
        TextFormField(
          controller: readingTextCtrl,
          decoration: const InputDecoration(
            labelText: 'Đoạn văn đọc *',
            border: OutlineInputBorder(),
            hintText: 'Nhập nội dung bài đọc...',
          ),
          maxLines: 10,
          validator: (value) =>
          value?.isEmpty ?? true ? 'Bắt buộc nhập đoạn văn' : null,
        ),
        const SizedBox(height: 16),
        _buildQuestionsSection(setState),
      ],
    );
  }

  Widget _buildWritingFields(StateSetter setState) {
    return Column(
      children: [
        TextFormField(
          controller: writingPromptCtrl,
          decoration: const InputDecoration(
            labelText: 'Đề bài viết *',
            border: OutlineInputBorder(),
            hintText: 'VD: Write about your hobby',
          ),
          maxLines: 3,
          validator: (value) =>
          value?.isEmpty ?? true ? 'Bắt buộc nhập đề bài' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: writingRequirementsCtrl,
          decoration: const InputDecoration(
            labelText: 'Yêu cầu',
            border: OutlineInputBorder(),
            hintText: 'VD: 50-70 words, Include: name, age, hobby',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        const Text(
          'Writing không cần câu hỏi trắc nghiệm',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildQuestionsSection(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [


            ElevatedButton.icon(
              onPressed: () {
                setState(() => _addQuestion());
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm câu hỏi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
            ),

        const SizedBox(height: 12),
        ...List.generate(questionControllers.length, (index) {
          return _buildQuestionCard(index, setState);
        }),
      ],
    );
  }

  Widget _buildQuestionCard(int index, StateSetter setState) {
    final controllers = questionControllers[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Câu hỏi ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() => _removeQuestion(index));
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controllers['question'],
              decoration: const InputDecoration(
                labelText: 'Câu hỏi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controllers['option1'],
              decoration: const InputDecoration(
                labelText: 'Lựa chọn 1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controllers['option2'],
              decoration: const InputDecoration(
                labelText: 'Lựa chọn 2',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controllers['option3'],
              decoration: const InputDecoration(
                labelText: 'Lựa chọn 3',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controllers['option4'],
              decoration: const InputDecoration(
                labelText: 'Lựa chọn 4',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: int.tryParse(controllers['correctIndex']?.text ?? '0') ?? 0,
              decoration: const InputDecoration(
                labelText: 'Đáp án đúng',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: 0, child: Text('Lựa chọn 1')),
                const DropdownMenuItem(value: 1, child: Text('Lựa chọn 2')),
                const DropdownMenuItem(value: 2, child: Text('Lựa chọn 3')),
                const DropdownMenuItem(value: 3, child: Text('Lựa chọn 4')),
              ],
              onChanged: (value) {
                controllers['correctIndex']?.text = value.toString();
              },
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _buildContentMap() {
    final content = <String, dynamic>{};

    switch (skill.value) {
      case 'listening':
        content['transcript'] = transcriptCtrl.text;
        if (audioUrlCtrl.text.isNotEmpty) {
          content['audioUrl'] = audioUrlCtrl.text;
        }
        content['questions'] = _buildQuestionsList();
        break;

      case 'speaking':
        final words = pronunciationCtrl.text
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        content['words'] = words;

        final sentences = exampleSentencesCtrl.text
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (sentences.isNotEmpty) {
          content['sentences'] = sentences;
        }
        break;

      case 'reading':
        content['text'] = readingTextCtrl.text;
        content['questions'] = _buildQuestionsList();
        break;

      case 'writing':
        content['prompt'] = writingPromptCtrl.text;
        if (writingRequirementsCtrl.text.isNotEmpty) {
          final requirements = writingRequirementsCtrl.text
              .split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          content['requirements'] = requirements;
        }
        break;
    }

    return content;
  }

  List<Map<String, dynamic>> _buildQuestionsList() {
    final questions = <Map<String, dynamic>>[];

    for (var i = 0; i < questionControllers.length; i++) {
      final controllers = questionControllers[i];
      final options = [
        controllers['option1']?.text ?? '',
        controllers['option2']?.text ?? '',
        controllers['option3']?.text ?? '',
        controllers['option4']?.text ?? '',
      ].where((e) => e.isNotEmpty).toList();

      if (options.length >= 2) {
        final correctIndex = int.tryParse(controllers['correctIndex']?.text ?? '0') ?? 0;
        questions.add({
          'id': 'q${i + 1}',
          'question': controllers['question']?.text ?? '',
          'options': options,
          'correctAnswer': options[correctIndex.clamp(0, options.length - 1)],
        });
      }
    }

    return questions;
  }

  Future<void> uploadLesson(BuildContext context, GlobalKey<FormState> formKey) async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final newLesson = LessonModel(
        id: '',
        title: titleCtrl.text,
        description: descriptionCtrl.text,
        level: level.value,
        skill: skill.value,
        topic: topicCtrl.text,
        content: _buildContentMap(),
        duration: int.tryParse(durationCtrl.text) ?? 10,
        difficulty: int.tryParse(difficultyCtrl.text) ?? 1,
      );

      await _firestore.collection('lessons').add(newLesson.toJson());

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bài học đã được thêm!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> showEditDialog(BuildContext context, LessonModel lesson) async {
    // Simplified edit - only basic info
    titleCtrl.text = lesson.title;
    descriptionCtrl.text = lesson.description;
    topicCtrl.text = lesson.topic;
    level.value = lesson.level;
    skill.value = lesson.skill;
    durationCtrl.text = lesson.duration.toString();
    difficultyCtrl.text = lesson.difficulty.toString();

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa Bài Học (Thông tin cơ bản)'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: _buildBasicInfoFields(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => editLesson(context, lesson.id, formKey),
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  Future<void> editLesson(BuildContext context, String lessonId, GlobalKey<FormState> formKey) async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final updateData = {
        'title': titleCtrl.text,
        'description': descriptionCtrl.text,
        'level': level.value,
        'skill': skill.value,
        'topic': topicCtrl.text,
        'duration': int.tryParse(durationCtrl.text) ?? 10,
        'difficulty': int.tryParse(difficultyCtrl.text) ?? 1,
      };

      await _firestore.collection('lessons').doc(lessonId).update(updateData);

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bài học đã được cập nhật!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> deleteLesson(BuildContext context, String lessonId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Bài Học'),
        content: const Text('Bạn có chắc chắn muốn xóa bài học này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Delete lesson
      await _firestore.collection('lessons').doc(lessonId).delete();

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bài học đã được xóa!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  AppRouter.router.go(Routes.login);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: Colors.red.shade700,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}