import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/question_model.dart';
import '../../../data/models/quiz_model.dart';
import '../../../resources/styles/colors.dart';
import '../../../resources/styles/text_styles.dart';
import '../../controllers/quiz_controller.dart';

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _numController = TextEditingController(text: '5');
  List<QuestionModel> _questions = [];
  int? _expandedIndex;
  late QuizController controller;

  final Map<String, TextEditingController> _questionControllers = {};
  final Map<String, List<TextEditingController>> _optionControllers = {};

  @override
  void initState() {
    super.initState();
    controller = Get.find<QuizController>();
    _titleController.addListener(_updateState);
    _descController.addListener(_updateState);
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool isQuizComplete = _titleController.text.isNotEmpty &&
        _questions.isNotEmpty &&
        _questions.every(_computeQuestionComplete) &&
        _questions.every(_isQuestionValid);

    final int completeQuestions = _questions.where(_computeQuestionComplete).length;
    final double completionPercentage = _questions.isEmpty
        ? 0
        : (completeQuestions / _questions.length * 100);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Quiz Mới', style: AppTextStyles.headline),
        backgroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildQuizInfoSection(completionPercentage),
                const SizedBox(height: 16),
                _buildQuestionList(),
                if (_questions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 32),
                    child: ElevatedButton(
                      onPressed: isQuizComplete ? _saveQuiz : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor:
                        isQuizComplete ? AppColors.primary : null,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: Text(
                        'Lưu Quiz',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                          isQuizComplete ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildQuizInfoSection(double completionPercentage) {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextFormField(
            cursorColor: Colors.grey,
            controller: _titleController,
            decoration: _inputDecoration('Tiêu đề Quiz'),
            validator: (value) =>
            value?.isEmpty ?? true ? 'Bắt buộc' : null,
            onChanged: (_) => _updateState(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            cursorColor: Colors.grey,
            controller: _descController,
            decoration: _inputDecoration('Mô tả (tùy chọn)'),
            maxLines: 2,
            onChanged: (_) => _updateState(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  cursorColor: Colors.grey,
                  controller: _numController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Số câu hỏi'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Bắt buộc';
                    final n = int.tryParse(value);
                    if (n == null || n <= 0) return 'Phải là số > 0';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _generateQuestions,
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                label: const Text('Tạo',
                    style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
          if (_questions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: completionPercentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      completionPercentage == 100
                          ? Colors.green
                          : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${completionPercentage.toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionList() {
    if (_questions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Nhập số lượng câu hỏi và nhấn "Tạo"',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(_questions.length, (index) {
        final q = _questions[index];
        final isExpanded = _expandedIndex == index;
        final isComplete = _computeQuestionComplete(q);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: Colors.grey.shade50,
          elevation: isExpanded ? 3 : 1,
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  _expandedIndex = isExpanded ? null : index;
                  _updateState();
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isComplete
                              ? Colors.green[100]
                              : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isComplete
                                  ? Colors.green[800]
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          q.question.isEmpty
                              ? 'Câu hỏi chưa có nội dung'
                              : q.question,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: q.question.isEmpty
                                ? Colors.grey[600]
                                : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        isComplete
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isComplete
                            ? Colors.green
                            : Colors.grey[400],
                      ),
                      const SizedBox(width: 8),
                      Icon(isExpanded
                          ? Icons.expand_less
                          : Icons.expand_more),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: _buildQuestionForm(q, index),
                ),
            ],
          ),
        );
      }),
    );
  }



  Widget _buildQuestionForm(QuestionModel question, int index) {
    _questionControllers.putIfAbsent(
      question.id,
          () {
        final c = TextEditingController(text: question.question);
        c.addListener(_updateState);
        return c;
      },
    );

    final questionController = _questionControllers[question.id]!;

    if (questionController.text != question.question) {
      questionController.text = question.question;
    }

    List<String> options = List.from(question.options);
    while (options.length < 4) options.add('');

    if (!_optionControllers.containsKey(question.id) ||
        _optionControllers[question.id]!.length != options.length) {
      _optionControllers[question.id]?.forEach((c) {
        c.removeListener(_updateState);
        c.dispose();
      });

      _optionControllers[question.id] =
          options.map((opt) {
            final c = TextEditingController(text: opt);
            c.addListener(_updateState);
            return c;
          }).toList();
    }

    final optionControllers = _optionControllers[question.id]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          cursorColor: Colors.grey,
          controller: questionController,
          decoration: _inputDecoration('Nội dung câu hỏi'),
          maxLines: 2,
          onChanged: (text) {
            _questions[index] =
                _questions[index].copyWith(question: text);
            _updateState();
          },
        ),
        const SizedBox(height: 16),
        const Text('Lựa chọn:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        ...List.generate(optionControllers.length, (i) {
          final optController = optionControllers[i];
          final currentValue =
          i < options.length ? options[i] : '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Radio<String>(
                  value: currentValue,
                  groupValue: question.correctAnswer ?? '',
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    if (val != null && val.isNotEmpty) {
                      _questions[index] = _questions[index]
                          .copyWith(correctAnswer: val);
                      _updateState();
                    }
                  },
                ),
                Expanded(
                  child: TextFormField(
                    cursorColor: Colors.grey,
                    controller: optController,
                    decoration: _inputDecoration('Lựa chọn ${i + 1}'),
                    onChanged: (text) {
                      final newOpts = List<String>.from(question.options);
                      while (newOpts.length <= i) newOpts.add('');
                      newOpts[i] = text;

                      String? newAnswer = question.correctAnswer;
                      if (newAnswer ==
                          currentValue) {
                        newAnswer =
                        text.isEmpty ? null : text;
                      }

                      _questions[index] = _questions[index]
                          .copyWith(options: newOpts, correctAnswer: newAnswer);
                      _updateState();
                    },
                  ),
                ),
                if (question.options.length > 2 &&
                    i < question.options.length)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      final newOpts = List<String>.from(question.options);
                      final removed =
                      newOpts.removeAt(i);
                      String? newAns = question.correctAnswer;
                      if (removed ==
                          question.correctAnswer) {
                        newAns = null;
                      }

                      _questions[index] = _questions[index]
                          .copyWith(options: newOpts, correctAnswer: newAns);
                      optController.dispose();
                      _optionControllers[question.id]!.removeAt(i);
                      _updateState();
                    },
                  ),
              ],
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () {
            final newOpts = List<String>.from(_questions[index].options)
              ..add('');
            _questions[index] = _questions[index].copyWith(options: newOpts);
            final c = TextEditingController();
            c.addListener(_updateState);
            _optionControllers[question.id]!.add(c);
            _updateState();
          },
          icon: Icon(Icons.add, color: AppColors.primary, size: 18),
          label:
          Text('Thêm lựa chọn', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }


  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: Colors.grey[700]),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide:
      BorderSide(color: AppColors.primary, width: 1),
    ),
    border:
    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
    fillColor: Colors.white,
  );

  bool _computeQuestionComplete(QuestionModel q) {
    final filled = q.options.where((e) => e.isNotEmpty).toList();
    return q.question.isNotEmpty &&
        filled.length >= 2 &&
        q.correctAnswer?.isNotEmpty == true &&
        filled.contains(q.correctAnswer!);
  }

  bool _isQuestionValid(QuestionModel q) {
    final opts = q.options.map((e) => e).where((e) => e.isNotEmpty).toList();
    if (opts.length < 2) return false;
    final unique = opts.map((e) => e.toLowerCase()).toSet();
    if (unique.length != opts.length) return false;
    return q.correctAnswer?.isNotEmpty == true &&
        opts.contains(q.correctAnswer!);
  }

  void _generateQuestions() {
    if (!_formKey.currentState!.validate()) return;
    final count = int.parse(_numController.text);
    _disposeAllControllers();
    _questions = List.generate(
      count,
          (_) => QuestionModel(id: const Uuid().v4(), question: '', options: []),
    );
    _expandedIndex = null;
    _updateState();
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    final isQuizComplete = _titleController.text.isNotEmpty &&
        _questions.isNotEmpty &&
        _questions.every(_computeQuestionComplete) &&
        _questions.every(_isQuestionValid);

    if (!isQuizComplete) {
      Get.snackbar(
        'Cảnh báo',
        'Vui lòng hoàn thành tất cả câu hỏi!',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    final quiz = QuizModel(
      id: const Uuid().v4(),
      title: _titleController.text,
      description: _descController.text,
      questions: _questions,
      createdAt: DateTime.now(),
      createdBy: 'current_user_id',
      totalQuestions: _questions.length,
      pdfFileName: null,
    );

    try {
      await controller.createQuiz(quiz);
      if (mounted) {
        Get.snackbar('Thành công', 'Quiz đã được lưu!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP);
        GoRouter.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar('Lỗi', 'Không thể lưu quiz: $e',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP);
      }
    }
  }

  void _disposeAllControllers() {
    for (var c in _questionControllers.values) {
      c.removeListener(_updateState);
      c.dispose();
    }
    _questionControllers.clear();

    for (var list in _optionControllers.values) {
      for (var c in list) {
        c.removeListener(_updateState);
        c.dispose();
      }
    }
    _optionControllers.clear();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _numController.dispose();
    _disposeAllControllers();
    super.dispose();
  }
}