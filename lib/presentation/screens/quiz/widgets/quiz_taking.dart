import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../../data/models/quiz_model.dart';
import '../../../../resources/styles/colors.dart';
import '../../../controllers/quiz_controller.dart';
import '../../../widgets/result_dialog.dart';

class QuizTakingScreen extends StatefulWidget {
  final String quizId;

  const QuizTakingScreen({
    super.key,
    required this.quizId,
  });

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  final controller = Get.find<QuizController>();

  int _currentQuestionIndex = 0;
  Map<String, String> _userAnswers = {};
  Map<String, bool> _answeredQuestions = {};
  bool _showResult = false;

  // Timer
  int _secondsElapsed = 0;
  bool _isTimerRunning = true;
  Timer? _timer;

  // Quiz state
  QuizModel? _quiz;
  bool _isLoading = true;
  String? _errorMessage;

  // Settings variables
  late int _autoAdvanceTime;
  late bool _shuffleQuestions;
  late bool _shuffleOptions;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _parseSettings();
      _loadQuiz();
      _isInitialized = true;
    }
  }

  // Method hiển thị mục lục câu hỏi - SIMPLE
  void _showQuestionIndex() {
    if (_quiz == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Danh sách câu hỏi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(Colors.green, 'Đã trả lời'),
                  const SizedBox(width: 12),
                  _buildLegendItem(Colors.grey.shade300, 'Chưa trả lời'),
                  const SizedBox(width: 12),
                  _buildLegendItem(AppColors.primary, 'Câu hiện tại'),
                ],
              ),
            ),

            // Question grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: _quiz!.questions.length,
                itemBuilder: (context, index) {
                  final question = _quiz!.questions[index];
                  final isAnswered = _answeredQuestions[question.id] ?? false;
                  final isCurrent = index == _currentQuestionIndex;

                  Color backgroundColor;
                  Color textColor;

                  if (isCurrent) {
                    backgroundColor = AppColors.primary;
                    textColor = Colors.white;
                  } else if (isAnswered) {
                    backgroundColor = Colors.green;
                    textColor = Colors.white;
                  } else {
                    backgroundColor = Colors.grey.shade300;
                    textColor = Colors.black87;
                  }

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _currentQuestionIndex = index;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  void _parseSettings() {
    final state = GoRouterState.of(context);
    final extra = state.extra as Map<String, dynamic>?;
    _autoAdvanceTime = extra?['autoAdvanceTime'] ?? 1;
    _shuffleQuestions = extra?['shuffleQuestions'] ?? false;
    _shuffleOptions = extra?['shuffleOptions'] ?? false;
  }

  Future<void> _loadQuiz() async {
    try {
      final quiz = await controller.getQuizById(widget.quizId);
      if (mounted) {
        setState(() {
          _quiz = quiz;
          if (_shuffleQuestions) {
            _quiz!.questions.shuffle();
          }
          if (_shuffleOptions) {
            for (var question in _quiz!.questions) {
              question.options.shuffle();
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không thể tải quiz: $e';
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isTimerRunning || !mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsElapsed++);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text(
            'Lỗi',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_quiz == null || _quiz!.questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text(
            'Quiz không hợp lệ',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
        ),
        body: const Center(
          child: Text('Không tìm thấy câu hỏi'),
        ),
      );
    }

    return _buildQuizScreen(_quiz!);
  }

  void _selectAnswer(String questionId, String answer) {
    final question = _quiz?.questions.firstWhere((q) => q.id == questionId);
    if (question == null) return;

    if (_answeredQuestions[questionId] ?? false) {
      return;
    }

    setState(() {
      _userAnswers[questionId] = answer;
      _answeredQuestions[questionId] = true;
    });

    if (!_isLastQuestion) {
      Future.delayed(Duration(seconds: _autoAdvanceTime), () {
        if (mounted) {
          _nextQuestion();
        }
      });
    }
  }

  void _nextQuestion() {
    setState(() {
      if (_currentQuestionIndex < (_quiz?.questions.length ?? 0) - 1) {
        _currentQuestionIndex++;
      }
    });
  }

  void _previousQuestion() {
    setState(() {
      if (_currentQuestionIndex > 0) {
        _currentQuestionIndex--;
      }
    });
  }

  bool get _isLastQuestion {
    final totalQuestions = _quiz?.questions.length ?? 0;
    return _currentQuestionIndex >= totalQuestions - 1;
  }

  void _submitQuiz() {
    final quiz = _quiz;
    if (quiz == null) return;

    final unanswered = quiz.questions.length - _userAnswers.length;
    if (unanswered > 0) {
      Get.dialog(
        AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Chưa hoàn thành',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          content: Text(
            'Bạn còn $unanswered câu chưa trả lời. Bạn có muốn nộp bài không?',
            style: TextStyle(color: Colors.grey[700]),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                'Hủy',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Get.back();
                _showResults();
              },
              child: const Text('Nộp bài'),
            ),
          ],
        ),
      );
    } else {
      _showResults();
    }
  }

  void _showResults() {
    final quiz = _quiz;
    if (quiz == null) return;

    final score = _calculateScore(quiz);
    final totalQuestions = quiz.questions.length;
    final percentage = (score / totalQuestions * 100).round();
    final isPassed = (score / totalQuestions) >= 0.7;
    final timeSpent = _formatTime(_secondsElapsed);

    final correctCount = score;
    final stats = <StatItem>[
      StatItem(
        icon: Icons.quiz_outlined,
        label: 'Câu trả lời đúng',
        value: '$correctCount/$totalQuestions',
        color: const Color(0xFF3B82F6),
      ),
      StatItem(
        icon: Icons.access_time_rounded,
        label: 'Thời gian',
        value: timeSpent,
        color: const Color(0xFF8B5CF6),
      ),
      if (quiz.difficulty != null)
        StatItem(
          icon: Icons.trending_up_rounded,
          label: 'Độ khó',
          value: _getDifficultyText(quiz.difficulty),
          color: const Color(0xFFEC4899),
        ),
    ];

    final buttons = <ButtonConfig>[
      ButtonConfig(
        text: 'Làm lại',
        onPressed: () {
          Navigator.of(context).pop();
          _retakeQuiz();
        },
        isPrimary: false,
        secondaryColor: const Color(0xFFFF9500),
      ),
      ButtonConfig(
        text: isPassed ? 'Hoàn thành' : 'Về trang chủ',
        onPressed: () {
          Navigator.of(context).pop();
          if (context.mounted) context.pop();
        },
        isPrimary: true,
        primaryColor: AppColors.primary,
      ),
    ];

    _isTimerRunning = false;

    GenericResultDialog.show(
      context,
      isSuccess: isPassed,
      successTitle: 'Xuất sắc!',
      failTitle: 'Cố gắng thêm!',
      subtitle: 'Kết quả quiz',
      successMessage: 'Chúc mừng! Bạn đã hoàn thành quiz',
      failMessage: 'Cần đạt 70% để hoàn thành',
      scoreLabel: 'Điểm số',
      score: percentage,
      totalScore: 100,
      successIcon: Icons.emoji_events,
      failIcon: Icons.sentiment_neutral,
      successColor: Colors.green,
      failColor: Colors.orange,
      stats: stats,
      buttons: buttons,
      successAnimationPath: 'lib/resources/assets/lottie/success.json',
      failAnimationPath: 'lib/resources/assets/lottie/fail.json',
    );
  }

  static String _getDifficultyText(dynamic difficulty) {
    if (difficulty == null) return 'Trung bình';
    final level = difficulty.toString().toLowerCase();
    if (level.contains('easy') || level == '1') return 'Dễ';
    if (level.contains('medium') || level == '2') return 'Trung bình';
    if (level.contains('hard') || level == '3') return 'Khó';
    return difficulty.toString();
  }

  void _retakeQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _userAnswers.clear();
      _answeredQuestions.clear();
      _showResult = false;
      _secondsElapsed = 0;
      _isTimerRunning = true;
      _timer?.cancel();
      _startTimer();
    });
  }

  int _calculateScore(QuizModel quiz) {
    int score = 0;
    for (final question in quiz.questions) {
      if (_userAnswers[question.id] == question.correctAnswer) {
        score++;
      }
    }
    return score;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildQuizScreen(QuizModel quiz) {
    final question = quiz.questions[_currentQuestionIndex];
    final totalQuestions = quiz.questions.length;
    final progress = (_currentQuestionIndex + 1) / totalQuestions;
    final isQuestionAnswered = _answeredQuestions[question.id] ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          quiz.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(_secondsElapsed),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),

          // Progress info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Câu ${_currentQuestionIndex + 1}/$totalQuestions',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '${_userAnswers.length}/$totalQuestions đã trả lời',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      question.question,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Options - BASIC & GREEN for correct
                  ...question.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = _userAnswers[question.id] == option;
                    final isCorrectAnswer = option == question.correctAnswer;

                    Color borderColor = Colors.grey.shade300;
                    Color backgroundColor = Colors.white;

                    if (isQuestionAnswered) {
                      if (isCorrectAnswer) {
                        // Đáp án đúng = màu xanh lá
                        borderColor = Colors.green;
                        backgroundColor = Colors.green.shade50;
                      } else if (isSelected && !isCorrectAnswer) {
                        // Đáp án sai được chọn = màu đỏ
                        borderColor = Colors.red;
                        backgroundColor = Colors.red.shade50;
                      }
                    } else if (isSelected) {
                      // Chưa submit, đang chọn
                      borderColor = AppColors.primary;
                      backgroundColor = Colors.white;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _selectAnswer(question.id, option),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                            color: backgroundColor,
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: isQuestionAnswered
                                      ? (isCorrectAnswer
                                      ? Colors.green
                                      : (isSelected ? Colors.red : Colors.grey.shade200))
                                      : (isSelected ? AppColors.primary : Colors.grey.shade200),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + index),
                                    style: TextStyle(
                                      color: isQuestionAnswered
                                          ? (isCorrectAnswer || isSelected
                                          ? Colors.white
                                          : Colors.black87)
                                          : (isSelected ? Colors.white : Colors.black87),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (isQuestionAnswered && isCorrectAnswer)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              if (isQuestionAnswered && isSelected && !isCorrectAnswer)
                                const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  // Explanation
                  if (isQuestionAnswered && question.explanation != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giải thích:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            question.explanation!,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom navigation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _showQuestionIndex,
                  icon: const Icon(Icons.grid_view, size: 18),
                  label: Text('${_currentQuestionIndex + 1}/${_quiz!.questions.length}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousQuestion,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Trước'),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLastQuestion ? _submitQuiz : _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(_isLastQuestion ? 'Nộp bài' : 'Tiếp'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _isTimerRunning = false;
    super.dispose();
  }
}