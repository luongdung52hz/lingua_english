import 'package:uuid/uuid.dart';
import '../../models/question_model.dart';

class QuizParser {
  final _uuid = const Uuid();

  Future<List<QuestionModel>> parse(String text) async {
    final questions = <QuestionModel>[];

    // Chuẩn hoá văn bản đầu vào
    text = _normalizeText(text);

    final format = _detectFormat(text);

    switch (format) {
      case QuizFormat.programming:
        questions.addAll(await _parseProgrammingFormat(text));
        break;
      case QuizFormat.standard:
        questions.addAll(await _parseStandardFormat(text));
        break;
      case QuizFormat.mixed:
        questions.addAll(await _parseMixedFormat(text));
        break;
      default:
        questions.addAll(await _parseGenericFormat(text));
        break;
    }

    return questions;
  }

  // ---------------------------
  // 🔍 Xác định định dạng
  // ---------------------------
  QuizFormat _detectFormat(String text) {
    if (RegExp(r'HA\(\d+\).*TA\(\d+,\d+\)', caseSensitive: false).hasMatch(text)) {
      return QuizFormat.programming;
    }
    if (RegExp(r'Câu\s+\d+', caseSensitive: false).hasMatch(text) &&
        RegExp(r'[A-D][\.\)]\s+', caseSensitive: false).hasMatch(text)) {
      return QuizFormat.standard;
    }
    if (text.contains('Câu') && text.contains('TA(')) {
      return QuizFormat.mixed;
    }
    return QuizFormat.generic;
  }

  // ---------------------------
  // 💻 Format có HA() / TA()
  // ---------------------------
  Future<List<QuestionModel>> _parseProgrammingFormat(String text) async {
    final questions = <QuestionModel>[];
    final lines = text.split('\n');

    final Map<int, String> questionTexts = {};
    final Map<int, List<String>> optionsMap = {};
    final Map<int, String> correctAnswersMap = {};

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('Phần')) continue;

      // Chuẩn hoá ngoặc kép
      line = line.replaceAll('“', '"').replaceAll('”', '"').replaceAll('„', '"');

      // Bỏ "(Một đáp án)" hoặc tương tự
      line = line.replaceAll(RegExp(r'\(.*đáp án.*\)', caseSensitive: false), '').trim();

      // HA(1)="Question"
      final haMatch = RegExp(r'HA\((\d+)\)\s*=\s*"(.+)"').firstMatch(line);
      if (haMatch != null) {
        final num = int.parse(haMatch.group(1)!);
        final question = haMatch.group(2)!.trim();
        questionTexts[num] = question;
        optionsMap[num] = [];
        continue;
      }

      // TA(1,2)="Option" hoặc *TA(1,2)="Option"
      final taMatch = RegExp(r'([*]?)TA\(\s*(\d+)\s*,\s*\d+\s*\)\s*=\s*"(.+)"').firstMatch(line);
      if (taMatch != null) {
        final isCorrect = taMatch.group(1) == '*';
        final num = int.parse(taMatch.group(2)!);
        final option = taMatch.group(3)!.trim();
        optionsMap[num] ??= [];
        optionsMap[num]!.add(option);
        if (isCorrect) correctAnswersMap[num] = option;
      }
    }

    for (final qNum in questionTexts.keys) {
      final qText = questionTexts[qNum]!;
      final opts = optionsMap[qNum] ?? [];
      final correct = correctAnswersMap[qNum];
      questions.add(QuestionModel(
        id: _uuid.v4(),
        question: qText,
        options: opts.take(4).toList(), // chỉ lấy tối đa 4 đáp án
        correctAnswer: correct,
      ));
    }

    return questions;
  }

  // ---------------------------
  // 📘 Format Câu 1, A), B)...
  // ---------------------------
  Future<List<QuestionModel>> _parseStandardFormat(String text) async {
    final questions = <QuestionModel>[];
    final questionBlocks = text.split(RegExp(r'Câu\s+\d+[:\.]', caseSensitive: false));

    for (int i = 1; i < questionBlocks.length; i++) {
      final block = questionBlocks[i].trim();
      if (block.isEmpty) continue;

      try {
        final question = _parseStandardQuestionBlock(block, i);
        questions.add(question);
      } catch (e) {
        print('⚠️ Lỗi parse câu $i: $e');
      }
    }
    return questions;
  }

  QuestionModel _parseStandardQuestionBlock(String block, int index) {
    final lines = block
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final questionText = lines.first;
    final options = <String>[];
    String? correctAnswer;

    for (var line in lines.skip(1)) {
      final optionMatch = RegExp(r'^[*]?[A-D]?[.\)]?\s*(.+)$').firstMatch(line);
      if (optionMatch != null) {
        final isCorrect = line.startsWith('*');
        final text = optionMatch.group(1)!.trim();
        if (text.isEmpty) continue;
        options.add(text);
        if (isCorrect) correctAnswer = text;
      }
    }

    return QuestionModel(
      id: _uuid.v4(),
      question: questionText,
      options: options.take(4).toList(),
      correctAnswer: correctAnswer,
    );
  }

  // ---------------------------
  // 🧩 Mixed format
  // ---------------------------
  Future<List<QuestionModel>> _parseMixedFormat(String text) async {
    final programming = await _parseProgrammingFormat(text);
    final standard = await _parseStandardFormat(text);
    return {...programming, ...standard}.toList();
  }

  // ---------------------------
  // 🧠 Generic fallback
  // ---------------------------
  Future<List<QuestionModel>> _parseGenericFormat(String text) async {
    final questions = <QuestionModel>[];
    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    String? currentQ;
    final currentOpts = <String>[];
    String? correct;

    for (final line in lines) {
      if (line.endsWith('?') || RegExp(r'^Câu\s+\d+', caseSensitive: false).hasMatch(line)) {
        if (currentQ != null && currentOpts.isNotEmpty) {
          questions.add(QuestionModel(
            id: _uuid.v4(),
            question: currentQ,
            options: List.from(currentOpts),
            correctAnswer: correct,
          ));
        }
        currentQ = line;
        currentOpts.clear();
        correct = null;
      } else {
        final m = RegExp(r'^[*]?[A-D]?[.\)]?\s*(.+)$').firstMatch(line);
        if (m != null && currentQ != null) {
          final isCorrect = line.startsWith('*');
          final text = m.group(1)!.trim();
          currentOpts.add(text);
          if (isCorrect) correct = text;
        }
      }
    }

    if (currentQ != null && currentOpts.isNotEmpty) {
      questions.add(QuestionModel(
        id: _uuid.v4(),
        question: currentQ,
        options: currentOpts.take(4).toList(),
        correctAnswer: correct,
      ));
    }

    return questions;
  }


  String _normalizeText(String input) {
    return input
        .replaceAll('\r', '\n')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('„', '"')
        .replaceAll(RegExp(r'\n{2,}'), '\n')
        .replaceAll(RegExp(r'Phần\s+[A-Z]+', caseSensitive: false), '')
        .trim();
  }

  // ---------------------------
  // ✅ Kiểm tra kết quả
  // ---------------------------
  List<String> validateQuestions(List<QuestionModel> questions) {
    final errors = <String>[];
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      if (q.question.isEmpty) {
        errors.add('Câu ${i + 1}: Thiếu nội dung câu hỏi');
      }
      if (q.options.length < 2) {
        errors.add('Câu ${i + 1}: Cần ít nhất 2 đáp án');
      }
      if (q.correctAnswer == null) {
        errors.add('Câu ${i + 1}: Thiếu đáp án đúng');
      }
    }
    return errors;
  }
}

enum QuizFormat { standard, programming, mixed, generic }
