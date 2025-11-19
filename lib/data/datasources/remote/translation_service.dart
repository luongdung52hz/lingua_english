// lib/data/datasources/remote/translation_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class TranslationResult {
  final String english;
  final String? vietnamese;
  final String? phonetic;
  final String? partOfSpeech;
  final List<String> examples;
  final String? imageUrl;

  TranslationResult({
    this.english = '',
    this.vietnamese,
    this.phonetic,
    this.partOfSpeech,
    this.examples = const [],
    this.imageUrl,
  });
}

enum TranslationDirection {
  viToEn,  // Việt → Anh
  enToVi,  // Anh → Việt
}

class TranslationService {
  static const String _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  final String apiKey;

  TranslationService({required this.apiKey});

  ///  SỬA: Thêm tham số direction (bắt buộc)
  Future<TranslationResult> translate(
      String text, {
        required TranslationDirection direction,
      }) async {
    print(' [START] Translation started for: "$text"');
    print(' [DIRECTION] User selected: ${direction == TranslationDirection.viToEn ? "Vietnamese → English" : "English → Vietnamese"}');

    //  SỬA: Dùng direction thay vì auto-detect
    final prompt = direction == TranslationDirection.viToEn
        ? _buildPromptViToEn(text)
        : _buildPromptEnToVi(text);

    try {
      print('API] Sending prompt to Gemini...');
      final response = await _callGemini(prompt);
      print(' [API] Gemini response received (code: 200)');

      print(' [CLEAN] Cleaning Markdown JSON...');
      final cleaned = _cleanMarkdownJson(response);
      print(' [CLEAN] Cleaned JSON: $cleaned');

      print(' [PARSE] Parsing JSON data...');
      final jsonData = jsonDecode(cleaned);
      print(' [PARSE] JSON parsed successfully. English: ${jsonData['english'] ?? 'N/A'}');

      final result = TranslationResult(
        english: jsonData['english'] ?? '',
        vietnamese: jsonData['vietnamese'],
        phonetic: jsonData['phonetic'],
        partOfSpeech: jsonData['partOfSpeech'],
        examples: List<String>.from(jsonData['examples'] ?? []),
        imageUrl: jsonData['imageUrl'],
      );

      print('[SUCCESS] Translation completed! Result: English="${result.english}", Vietnamese="${result.vietnamese ?? 'N/A'}", Examples=${result.examples.length}');
      return result;
    } catch (e) {
      print(' [ERROR] Translation failed at step: $e');
      print(' [END] Translation process aborted due to error.');
      rethrow;
    } finally {
      print(' [END] Translation process finished (success or error).');
    }
  }

  /// Xây prompt cho Việt → Anh
  String _buildPromptViToEn(String vietnamese) => '''
Dịch từ tiếng Việt sang tiếng Anh và cung cấp thông tin chi tiết cho từ: "$vietnamese".

Trả về JSON đúng định dạng sau:
{
  "english": "bản dịch sang tiếng Anh đơn giản",
  "vietnamese": "$vietnamese",
  "phonetic": "/IPA tiếng Anh/" (nếu có),
  "partOfSpeech": "noun/verb/adjective",
  "examples": ["Câu ví dụ tiếng Anh 1", "dịch tiếng Việt của câu tiếng Anh 1"],
  "imageUrl": null
}

Chỉ trả về JSON, không thêm chữ khác.
''';

  /// Xây prompt cho Anh → Việt
  String _buildPromptEnToVi(String english) => '''
Dịch từ tiếng Anh sang tiếng Việt và cung cấp thông tin chi tiết cho từ: "$english".

Trả về JSON đúng định dạng sau:
{
  "english": "$english",
  "vietnamese": "bản dịch sang tiếng Việt đơn giản",
  "phonetic": "/IPA tiếng Anh/" (nếu có),
  "partOfSpeech": "noun/verb/adjective",
  "examples": ["Câu ví dụ tiếng Anh 1", "dịch tiếng Việt câu tiếng Anh 1"],
  "imageUrl": null
}

Chỉ trả về JSON, không thêm chữ khác.
Chỉ trả về 1 cặp câu ví dụ.
''';

  /// Dọn JSON từ Markdown
  String _cleanMarkdownJson(String response) {
    print(' [CLEAN] Original response snippet: ${response.substring(0, min(100, response.length))}...');
    final cleaned = response
        .trim()
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\s*```$', multiLine: true), '');

    if (cleaned.isEmpty) {
      print(' [CLEAN] Error: Empty after cleaning!');
      throw Exception('Empty response after cleaning');
    }
    return cleaned;
  }

  /// Gọi Gemini API
  Future<String> _callGemini(String prompt) async {
    print(' [API] Calling Gemini with prompt length: ${prompt.length} chars');

    final response = await http.post(
      Uri.parse('$_geminiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 1500}
      }),
    );

    print(' [API] Response status: ${response.statusCode}');
    if (response.statusCode != 200) {
      print(' [API] Error body: ${response.body}');
      throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    final result = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
    if (result == null) {
      print(' [API] No text in response: ${response.body.substring(0, 200)}...');
      throw Exception('No text found in Gemini response');
    }
    print(' [API] Text extracted successfully (length: ${result.length})');
    return result;
  }
}