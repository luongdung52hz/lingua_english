import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/question_model.dart';
import 'package:uuid/uuid.dart';

class AIQuizService {
  final String _apiKey;
  final String _model = 'gemini-2.0-flash-exp';
  final _uuid = const Uuid();

  // ⚙️ Cấu hình tối ưu để tránh rate limit
  static const int _chunkSize = 8; // Tăng lại vì giờ xử lý tuần tự
  static const int _maxRetries = 5; // Tăng số retry
  static const Duration _baseTimeout = Duration(seconds: 60);
  static const Duration _delayBetweenRequests = Duration(seconds: 3); // Delay giữa mỗi request
  static const Duration _retryDelay = Duration(seconds: 10); // Delay khi bị 429

  AIQuizService({required String apiKey}) : _apiKey = apiKey;

  /// 🚀 Parse toàn bộ text bằng AI (SEQUENTIAL để tránh rate limit)
  Future<List<QuestionModel>> parseTextToJSON(String text) async {
    try {
      final cleanedText = _preCleanText(text);
      final chunks = _splitIntoChunks(cleanedText);

      print('📦 Chia thành ${chunks.length} chunks (${_chunkSize} câu/chunk)');
      print('⏱️ Ước tính thời gian: ~${(chunks.length * 4)} giây');

      final allQuestions = <QuestionModel>[];

      // XỬ LÝ TUẦN TỰ (sequential) thay vì parallel để tránh rate limit
      for (var i = 0; i < chunks.length; i++) {
        print('⚡ Processing chunk ${i + 1}/${chunks.length}');

        final questions = await _parseChunkWithAI(chunks[i], i);
        allQuestions.addAll(questions);

        // Delay giữa các request (QUAN TRỌNG để tránh 429)
        if (i < chunks.length - 1) {
          print('⏳ Chờ ${_delayBetweenRequests.inSeconds}s trước chunk tiếp theo...');
          await Future.delayed(_delayBetweenRequests);
        }
      }

      print('✅ Tổng cộng parse được ${allQuestions.length} câu hỏi');

      if (allQuestions.isEmpty) {
        throw Exception('Không parse được câu hỏi nào. Vui lòng kiểm tra lại định dạng văn bản.');
      }

      return allQuestions;
    } catch (e) {
      print('❌ Lỗi parse: $e');
      rethrow;
    }
  }

  /// 🔹 Pre-clean text
  String _preCleanText(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) {
      if (line.isEmpty) return false;
      if (line.startsWith('Page ')) return false;
      if (line.toLowerCase().contains('eduquiz')) return false;
      if (RegExp(r'^\d{1,2}/\d{1,2}/\d{2,4}').hasMatch(line)) return false;
      return true;
    })
        .join('\n')
        .trim();
  }

  /// 🔹 Chia text thành chunks
  List<String> _splitIntoChunks(String text) {
    final lines = text.split('\n');
    final chunks = <String>[];
    final buffer = StringBuffer();
    int questionCount = 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      buffer.writeln(line);

      if (_looksLikeQuestion(line)) {
        questionCount++;
      }

      if (questionCount >= _chunkSize || i == lines.length - 1) {
        if (buffer.toString().trim().isNotEmpty) {
          chunks.add(buffer.toString().trim());
          buffer.clear();
          questionCount = 0;
        }
      }
    }

    return chunks.where((c) => c.isNotEmpty).toList();
  }

  /// 🔹 Kiểm tra câu hỏi
  bool _looksLikeQuestion(String line) {
    return RegExp(r'^\d+[\.).\s]').hasMatch(line) ||
        RegExp(r'^Câu\s+\d+', caseSensitive: false).hasMatch(line) ||
        line.endsWith('?');
  }

  /// 🤖 Parse 1 chunk với exponential backoff cho 429 error
  Future<List<QuestionModel>> _parseChunkWithAI(String chunk, int chunkIndex) async {
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final timeout = _baseTimeout * (attempt + 1);
        print('🔄 Chunk ${chunkIndex + 1} - Attempt ${attempt + 1}/${_maxRetries}');

        return await _callAIParseAPI(chunk, chunkIndex).timeout(timeout);

      } on TimeoutException catch (e) {
        print('⏱️ Chunk ${chunkIndex + 1} timeout');

        if (attempt == _maxRetries - 1) {
          print('❌ Chunk ${chunkIndex + 1} failed sau ${_maxRetries} lần thử');
          return [];
        }

        await Future.delayed(Duration(seconds: 5 * (attempt + 1)));

      } catch (e) {
        final errorStr = e.toString();

        // XỬ LÝ RIÊNG CHO 429 ERROR
        if (errorStr.contains('429') || errorStr.contains('RESOURCE_EXHAUSTED')) {
          print('🚫 Rate limit hit! Chunk ${chunkIndex + 1}');

          if (attempt == _maxRetries - 1) {
            print('❌ Chunk ${chunkIndex + 1} vẫn bị rate limit sau ${_maxRetries} lần thử');
            return [];
          }

          // Exponential backoff: 10s, 20s, 30s, 40s, 50s
          final delay = _retryDelay * (attempt + 1);
          print('⏳ Đợi ${delay.inSeconds}s do rate limit...');
          await Future.delayed(delay);

        } else {
          // Lỗi khác (network, parsing, etc.)
          print('⚠️ Chunk ${chunkIndex + 1} error: $e');

          if (attempt == _maxRetries - 1) {
            return [];
          }

          await Future.delayed(Duration(seconds: 3 * (attempt + 1)));
        }
      }
    }
    return [];
  }

  /// 🌐 Gọi API Gemini
  Future<List<QuestionModel>> _callAIParseAPI(String chunk, int chunkIndex) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final prompt = _buildParsePrompt(chunk);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 8000,
          'topP': 0.95,
          'topK': 40,
        }
      }),
    );

    // XỬ LÝ CÁC MÃ LỖI
    if (response.statusCode == 429) {
      // Rate limit - throw để trigger retry logic
      throw Exception('API error: 429 - ${response.body}');
    }

    if (response.statusCode == 503) {
      // Service unavailable
      throw Exception('API error: 503 - Service temporarily unavailable');
    }

    if (response.statusCode != 200) {
      print('❌ API Error: ${response.statusCode} - ${response.body}');
      throw Exception('API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);

    if (data['candidates'] == null || (data['candidates'] as List).isEmpty) {
      throw Exception('Empty candidates from AI');
    }

    final candidate = data['candidates'][0];

    // Kiểm tra blocked content
    if (candidate['finishReason'] == 'SAFETY' ||
        candidate['finishReason'] == 'RECITATION' ||
        candidate['finishReason'] == 'OTHER') {
      print('⚠️ Content blocked: ${candidate['finishReason']}');
      throw Exception('Content blocked by AI safety filters');
    }

    // Extract text với fallback paths
    String? jsonText = candidate['content']?['parts']?[0]?['text'];

    if (jsonText == null || jsonText.toString().trim().isEmpty) {
      jsonText = candidate['output']?['text'] ?? candidate['text'];
    }

    if (jsonText == null || jsonText.toString().trim().isEmpty) {
      throw Exception('Empty response from AI');
    }

    return _parseAIResponse(jsonText);
  }

  /// 📝 Build prompt
  String _buildParsePrompt(String chunk) {
    return '''
Chuyển đổi các câu hỏi trắc nghiệm tiếng Việt sau thành JSON array.

ĐỊNH DẠNG:
- Câu hỏi: bắt đầu "Câu X:", "X.", "X)" hoặc kết thúc "?"
- Đáp án: "A)", "B)", "C)", "D)" (dấu * = đúng)
- Mỗi câu có 4 đáp án

QUY TẮC:
1. Xóa số thứ tự câu hỏi
2. Xóa ký tự đáp án (A), B., v.v.)
3. Thêm đáp án nếu thiếu
4. Sửa lỗi chính tả

OUTPUT JSON:
[
  {
    "question": "Nội dung câu hỏi",
    "options": ["A", "B", "C", "D"],
    "correctAnswer": "Đáp án đúng hoặc null"
  }
]

TEXT:
$chunk

CHỈ JSON, KHÔNG TEXT KHÁC.
''';
  }

  /// 🔍 Parse AI response
  List<QuestionModel> _parseAIResponse(String jsonText) {
    try {
      final cleanJson = jsonText
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      if (cleanJson.isEmpty) return [];

      final List<dynamic> jsonArray = jsonDecode(cleanJson);

      return jsonArray.map((item) {
        try {
          final question = item['question']?.toString().trim() ?? '';
          final options = (item['options'] as List?)
              ?.map((o) => o.toString().trim())
              .toList() ?? [];
          final correctAnswer = item['correctAnswer']?.toString().trim();

          if (question.length < 5 || options.length < 2) return null;

          while (options.length < 4) {
            options.add('Không có đáp án này');
          }
          if (options.length > 4) {
            options.removeRange(4, options.length);
          }

          return QuestionModel(
            id: _uuid.v4(),
            question: question,
            options: options,
            correctAnswer: correctAnswer?.isNotEmpty == true ? correctAnswer : null,
          );
        } catch (e) {
          return null;
        }
      }).whereType<QuestionModel>().toList();

    } catch (e) {
      print('❌ Parse JSON error: $e');
      return [];
    }
  }

  /// 🎯 Generate quiz title
  Future<String> generateQuizTitle(String sampleText) async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
      );

      final prompt = '''
Tạo tiêu đề ngắn gọn (max 50 ký tự) cho quiz:

$sampleText

Chỉ tiêu đề.
''';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 100,
          }
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final title = data['candidates']?[0]?['content']?['parts']?[0]?['text']
            ?.toString()
            .trim() ?? 'Quiz từ PDF';
        return title.length > 50 ? title.substring(0, 50) : title;
      }
    } catch (e) {
      print('⚠️ Lỗi generate title: $e');
    }
    return 'Quiz từ PDF';
  }
}