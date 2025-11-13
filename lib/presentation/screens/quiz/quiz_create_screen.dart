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
    final bool isQuizComplete = _titleController.text.trim().isNotEmpty &&
        _questions.isNotEmpty &&
        _questions.every(_computeQuestionComplete) &&
        _questions.every((q) => _isQuestionValid(q));

    final int completeQuestions = _questions.where(_computeQuestionComplete).length;
    final double completionPercentage = _questions.isEmpty ? 0 : (completeQuestions / _questions.length * 100);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Quiz Mới',style: AppTextStyles.headline,),
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
                Container(
                  color: Colors.grey[50],
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        cursorColor: Colors.grey,
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề Quiz',
                          labelStyle: TextStyle(color: Colors.grey[700]),
                          floatingLabelStyle: MaterialStateTextStyle.resolveWith(
                                (Set<MaterialState> states) {
                              if (states.contains(MaterialState.focused)) {
                                return TextStyle(color: AppColors.primary);
                              }
                              return TextStyle(color: Colors.grey[700]);
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.primary, width: 1),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) =>
                        value?.isEmpty ?? true ? 'Bắt buộc' : null,
                        onChanged: (_) => _updateState(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        cursorColor: Colors.grey,
                        controller: _descController,
                        decoration: InputDecoration(
                          labelText: 'Mô tả (tùy chọn)',
                          labelStyle: TextStyle(color: Colors.grey[700]),
                          floatingLabelStyle: MaterialStateTextStyle.resolveWith(
                                (Set<MaterialState> states) {
                              if (states.contains(MaterialState.focused)) {
                                return TextStyle(color: AppColors.primary);
                              }
                              return TextStyle(color: Colors.grey[700]);
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.primary, width: 1),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              cursorColor: Colors.grey,
                              controller: _numController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Số câu hỏi',
                                labelStyle: TextStyle(color: Colors.grey[700]),
                                floatingLabelStyle: MaterialStateTextStyle.resolveWith(
                                      (Set<MaterialState> states) {
                                    if (states.contains(MaterialState.focused)) {
                                      return TextStyle(color: AppColors.primary);
                                    }
                                    return TextStyle(color: Colors.grey[700]);
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppColors.primary, width: 1),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Bắt buộc';
                                }
                                final n = int.tryParse(value);
                                if (n == null || n <= 0) return 'Phải là số > 0';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _generateQuestions,
                            icon: const Icon(Icons.add, color: Colors.white,size: 20,),
                            label: const Text(
                              'Tạo',
                              style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                ),

                const SizedBox(height: 16),

                if (_questions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Nhập số lượng câu hỏi và nhấn "Tạo"',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                else
                  ...List.generate(_questions.length, (index) {
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
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
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
                                        const SizedBox(height: 4),
                                        Text(
                                          '${q.options.where((o) => o.trim().isNotEmpty).length} lựa chọn',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
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
                              decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  border: Border(
                                    top: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  borderRadius: BorderRadius.circular(30)
                              ),
                              padding: const EdgeInsets.all(16),
                              child: _buildQuestionForm(q, index),
                            ),
                        ],
                      ),
                    );
                  }),

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
                        backgroundColor: isQuizComplete ? AppColors.primary : null,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: Text(
                        'Lưu Quiz',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isQuizComplete ? Colors.white : Colors.grey[600],
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

  Widget _buildQuestionForm(QuestionModel question, int index) {
    _questionControllers.putIfAbsent(
      question.id,
          () {
        final controller = TextEditingController(text: question.question);
        controller.addListener(_updateState);
        return controller;
      },
    );
    final questionController = _questionControllers[question.id]!;

    if (questionController.text != question.question) {
      questionController.text = question.question;
    }

    List<String> displayOptions = List.from(question.options);
    while (displayOptions.length < 4) {
      displayOptions.add('');
    }

    if (!_optionControllers.containsKey(question.id) ||
        _optionControllers[question.id]!.length != displayOptions.length) {
      _optionControllers[question.id]?.forEach((c) {
        c.removeListener(_updateState);
        c.dispose();
      });

      _optionControllers[question.id] = displayOptions
          .map((opt) {
        final controller = TextEditingController(text: opt);
        controller.addListener(_updateState);
        return controller;
      })
          .toList();
    }

    final optionControllers = _optionControllers[question.id]!;

    for (int i = 0; i < optionControllers.length; i++) {
      if (i < displayOptions.length &&
          optionControllers[i].text != displayOptions[i]) {
        optionControllers[i].text = displayOptions[i];
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          cursorColor: Colors.grey,
          controller: questionController,
          decoration: InputDecoration(
            labelText: 'Nội dung câu hỏi',
            labelStyle: TextStyle(color: Colors.grey[700]),
            floatingLabelStyle: MaterialStateTextStyle.resolveWith(
                  (Set<MaterialState> states) {
                if (states.contains(MaterialState.focused)) {
                  return TextStyle(color: AppColors.primary);
                }
                return TextStyle(color: Colors.grey[700]);
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 1),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          maxLines: 2,
          onChanged: (newText) {
            _questions[index] = _questions[index].copyWith(
              question: newText,
            );
            _updateState();
          },
        ),
        const SizedBox(height: 16),

        const Text(
          'Lựa chọn:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),

        ...List.generate(optionControllers.length, (optIndex) {
          final controller = optionControllers[optIndex];
          final currentValue = optIndex < displayOptions.length
              ? displayOptions[optIndex]
              : '';

          // So sánh bằng trim để tránh lỗi khoảng trắng
          final isSelected = currentValue.trim().isNotEmpty &&
              question.correctAnswer?.trim() == currentValue.trim();

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Radio<String>(
                  value: currentValue.trim(),
                  groupValue: question.correctAnswer?.trim() ?? '',
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    if (currentValue.trim().isNotEmpty) {
                      // LƯU Ý: Lưu giá trị ĐÃ TRIM
                      _questions[index] = _questions[index].copyWith(
                        correctAnswer: currentValue.trim(),
                      );
                      _updateState();
                    }
                  },
                ),
                Expanded(
                  child: TextFormField(
                    cursorColor: Colors.grey,
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Lựa chọn ${optIndex + 1}',
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      floatingLabelStyle: MaterialStateTextStyle.resolveWith(
                            (Set<MaterialState> states) {
                          if (states.contains(MaterialState.focused)) {
                            return TextStyle(color: AppColors.primary);
                          }
                          return TextStyle(color: Colors.grey[700]);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.primary, width: 1),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (newText) {
                      final currentOptions = List<String>.from(question.options);

                      while (currentOptions.length <= optIndex) {
                        currentOptions.add('');
                      }

                      final oldValue = currentOptions[optIndex].trim();
                      currentOptions[optIndex] = newText;

                      while (currentOptions.isNotEmpty &&
                          currentOptions.last.trim().isEmpty &&
                          currentOptions.length > 4) {
                        final lastIndex = currentOptions.length - 1;
                        if (lastIndex >= 4) {
                          currentOptions.removeAt(lastIndex);
                        } else {
                          break;
                        }
                      }

                      // Cập nhật correctAnswer nếu đang chỉnh sửa option được chọn
                      String? newCorrectAnswer = question.correctAnswer;
                      if (question.correctAnswer?.trim() == oldValue) {
                        newCorrectAnswer = newText.trim().isNotEmpty ? newText.trim() : null;
                      }

                      _questions[index] = _questions[index].copyWith(
                        options: currentOptions,
                        correctAnswer: newCorrectAnswer,
                      );

                      _updateState();
                    },
                  ),
                ),
                if (question.options.length > 2 &&
                    optIndex < question.options.length &&
                    currentValue.trim().isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: Colors.black,
                    onPressed: () {
                      final newOptions = List<String>.from(question.options);
                      String? removedValue;

                      if (optIndex < newOptions.length) {
                        removedValue = newOptions.removeAt(optIndex).trim();
                      }

                      String? newCorrectAnswer = question.correctAnswer;
                      if (removedValue != null &&
                          question.correctAnswer?.trim() == removedValue) {
                        newCorrectAnswer = null;
                      }

                      _questions[index] = _questions[index].copyWith(
                        options: newOptions,
                        correctAnswer: newCorrectAnswer,
                      );

                      optionControllers[optIndex].removeListener(_updateState);
                      optionControllers[optIndex].dispose();
                      optionControllers.removeAt(optIndex);

                      _updateState();
                    },
                  ),
              ],
            ),
          );
        }),

        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            final newOptions = List<String>.from(_questions[index].options);
            newOptions.add('');
            _questions[index] = _questions[index].copyWith(
              options: newOptions,
            );

            final newController = TextEditingController(text: '');
            newController.addListener(_updateState);
            _optionControllers[question.id]!.add(newController);

            _updateState();
          },
          icon: Icon(Icons.add, size: 18, color: AppColors.primary),
          label: Text(
            'Thêm lựa chọn',
            style: TextStyle(color: AppColors.primary),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  bool _computeQuestionComplete(QuestionModel question) {
    final nonEmptyOptions = question.options
        .map((e) => e.trim())
        .where((opt) => opt.isNotEmpty)
        .toList();

    return question.question.trim().isNotEmpty &&
        nonEmptyOptions.length >= 2 &&
        question.correctAnswer != null &&
        question.correctAnswer!.trim().isNotEmpty &&
        nonEmptyOptions.contains(question.correctAnswer!.trim());
  }

  bool _isQuestionValid(QuestionModel question) {
    final nonEmptyOptions = question.options
        .map((e) => e.trim())
        .where((opt) => opt.isNotEmpty)
        .toList();

    if (nonEmptyOptions.length < 2) return false;

    // Kiểm tra trùng lặp (case-insensitive)
    final uniqueOptions = nonEmptyOptions.map((e) => e.toLowerCase()).toSet();
    if (uniqueOptions.length != nonEmptyOptions.length) return false;

    // Kiểm tra đáp án đúng có trong danh sách
    return question.correctAnswer?.trim().isNotEmpty == true &&
        nonEmptyOptions.contains(question.correctAnswer!.trim());
  }

  void _generateQuestions() {
    if (!_formKey.currentState!.validate()) return;
    final count = int.parse(_numController.text);

    _disposeAllControllers();

    _questions = List.generate(
      count,
          (_) => QuestionModel(
        id: const Uuid().v4(),
        question: '',
        options: [],
      ),
    );
    _expandedIndex = null;

    _updateState();
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate() || !mounted) return;

    final bool isQuizComplete = _titleController.text.trim().isNotEmpty &&
        _questions.isNotEmpty &&
        _questions.every(_computeQuestionComplete) &&
        _questions.every((q) => _isQuestionValid(q));

    if (!isQuizComplete) {
      final incompleteQuestions = _questions.asMap().entries
          .where((entry) => !_computeQuestionComplete(entry.value))
          .map((e) => 'Câu ${e.key + 1}')
          .toList();
      final invalidQuestions = _questions.asMap().entries
          .where((entry) => !_isQuestionValid(entry.value))
          .map((e) => 'Câu ${e.key + 1}')
          .toList();

      String message = 'Vui lòng hoàn thành tất cả câu hỏi trước khi lưu!';
      if (incompleteQuestions.isNotEmpty) {
        message += '\n\nChưa hoàn thành: ${incompleteQuestions.join(', ')}';
      }
      if (invalidQuestions.isNotEmpty) {
        message += '\n\nLỗi validation: ${invalidQuestions.join(', ')}';
        message += '\n(Kiểm tra lựa chọn trùng lặp hoặc đáp án sai)';
      }

      Get.snackbar(
        'Cảnh báo',
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return;
    }

    final quiz = QuizModel(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      questions: _questions.map((q) => q.copyWith(
        question: q.question.trim(),
        options: q.options.map((o) => o.trim()).where((o) => o.isNotEmpty).toList(),
        correctAnswer: q.correctAnswer?.trim(),
      )).toList(),
      createdAt: DateTime.now(),
      createdBy: 'current_user_id',
      pdfFileName: null,
      totalQuestions: _questions.length,
    );

    try {
      await controller.createQuiz(quiz);
      if (mounted) {
        Get.snackbar(
          'Thành công',
          'Quiz đã được lưu!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        GoRouter.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Lỗi',
          'Không thể lưu quiz: ${e.toString()}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  void _disposeAllControllers() {
    for (var controller in _questionControllers.values) {
      controller.removeListener(_updateState);
      controller.dispose();
    }
    _questionControllers.clear();

    for (var controllers in _optionControllers.values) {
      for (var controller in controllers) {
        controller.removeListener(_updateState);
        controller.dispose();
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