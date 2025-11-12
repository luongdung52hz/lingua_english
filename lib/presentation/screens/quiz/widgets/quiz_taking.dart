import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../../data/models/quiz_model.dart';
import '../../../controllers/quiz_controller.dart';

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

  // Method hiển thị mục lục câu hỏi
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Danh sách câu hỏi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Legend
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(Colors.green, 'Đã trả lời'),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.grey[300]!, 'Chưa trả lời'),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.blue, 'Câu hiện tại'),
                ],
              ),
            ),

            // Question grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
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
                    backgroundColor = Colors.blue;
                    textColor = Colors.white;
                  } else if (isAnswered) {
                    backgroundColor = Colors.green;
                    textColor = Colors.white;
                  } else {
                    backgroundColor = Colors.grey[300]!;
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
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
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
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadQuiz,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_quiz == null || _quiz!.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz không hợp lệ')),
        body: const Center(
          child: Text('Không tìm thấy câu hỏi'),
        ),
      );
    }

    return _showResult
        ? _buildResultScreen(_quiz!)
        : _buildQuizScreen(_quiz!);
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
          title: const Text('Chưa hoàn thành'),
          content: Text('Bạn còn $unanswered câu chưa trả lời. Bạn có muốn nộp bài không?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
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
    setState(() {
      _isTimerRunning = false;
      _showResult = true;
    });
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
      _isLoading = true;
      _loadQuiz();
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
      appBar: AppBar(
        title: Text(quiz.title),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _formatTime(_secondsElapsed),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: progress, minHeight: 6),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Câu ${_currentQuestionIndex + 1}/$totalQuestions',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_userAnswers.length}/$totalQuestions đã trả lời',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        question.question,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ...question.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = _userAnswers[question.id] == option;
                    final isCorrectAnswer = option == question.correctAnswer;

                    Color borderColor = Colors.grey[300]!;
                    Color backgroundColor = Colors.white;

                    if (isQuestionAnswered) {
                      if (isCorrectAnswer) {
                        borderColor = Colors.green;
                        backgroundColor = Colors.green[50]!;
                      } else if (isSelected && !isCorrectAnswer) {
                        borderColor = Colors.red;
                        backgroundColor = Colors.red[50]!;
                      }
                    } else if (isSelected) {
                      borderColor = Colors.blue;
                      backgroundColor = Colors.blue[50]!;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _selectAnswer(question.id, option),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: borderColor,
                              width: isSelected || (isQuestionAnswered && isCorrectAnswer) ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: backgroundColor,
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isQuestionAnswered
                                      ? (isCorrectAnswer
                                      ? Colors.green
                                      : (isSelected ? Colors.red : Colors.grey[200]))
                                      : (isSelected ? Colors.blue : Colors.grey[200]),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + index),
                                    style: TextStyle(
                                      color: isQuestionAnswered
                                          ? (isCorrectAnswer || isSelected ? Colors.white : Colors.black)
                                          : (isSelected ? Colors.white : Colors.black),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                    color: isQuestionAnswered && isCorrectAnswer ? Colors.green : null,
                                  ),
                                ),
                              ),
                              if (isSelected || (isQuestionAnswered && isCorrectAnswer))
                                Icon(
                                  isQuestionAnswered
                                      ? (isCorrectAnswer ? Icons.check_circle : Icons.cancel)
                                      : Icons.check_circle,
                                  color: isQuestionAnswered
                                      ? (isCorrectAnswer ? Colors.green : Colors.red)
                                      : Colors.blue,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  if (isQuestionAnswered && question.explanation != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.orange[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Giải thích:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              question.explanation!,
                              style: TextStyle(
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _showQuestionIndex,
                  icon: const Icon(Icons.grid_view),
                  label: Text('${_currentQuestionIndex + 1}/$totalQuestions'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                ),
                const SizedBox(width: 12),
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previousQuestion,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Trước'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLastQuestion ? _submitQuiz : _nextQuestion,
                    icon: Icon(_isLastQuestion ? Icons.check : Icons.arrow_forward),
                    label: Text(_isLastQuestion ? 'Nộp bài' : 'Tiếp'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen(QuizModel quiz) {
    final score = _calculateScore(quiz);
    final totalQuestions = quiz.questions.length;
    final percentage = (score / totalQuestions * 100).toStringAsFixed(1);
    final isPassed = (score / totalQuestions) >= 0.7;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: isPassed ? Colors.green[50] : Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      isPassed ? Icons.emoji_events : Icons.sentiment_neutral,
                      size: 64,
                      color: isPassed ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isPassed ? 'Xuất sắc!' : 'Cố gắng thêm!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$score/$totalQuestions câu đúng',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Thời gian: ${_formatTime(_secondsElapsed)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Chi tiết câu trả lời:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...quiz.questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              final userAnswer = _userAnswers[question.id];
              final isCorrect = userAnswer == question.correctAnswer;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCorrect ? Colors.green : Colors.red,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              question.question,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (userAnswer != null) ...[
                        Text(
                          'Câu trả lời của bạn: $userAnswer',
                          style: TextStyle(
                            color: isCorrect ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],

                      if (!isCorrect && question.correctAnswer != null) ...[
                        Text(
                          'Đáp án đúng: ${question.correctAnswer}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],

                      if (question.explanation != null) ...[
                        const Divider(height: 16),
                        Text(
                          'Giải thích:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          question.explanation!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _retakeQuiz,
              icon: const Icon(Icons.refresh),
              label: const Text('Làm lại'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                if (context.mounted) context.pop();
              },
              icon: const Icon(Icons.home),
              label: const Text('Về trang chủ'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
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