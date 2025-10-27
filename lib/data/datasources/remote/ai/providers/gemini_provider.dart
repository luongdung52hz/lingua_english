import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';

class GeminiProvider implements AIProvider {
  @override
  final String apiKey;

  @override
  final Duration timeout;

  @override
  final int maxRetries;

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  GeminiProvider({
    required this.apiKey,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 2,
  });

  @override
  String get name => 'Gemini';

  @override
  Future<String> generate(String prompt) async {
    Exception? lastError;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          print('🔄 Gemini retry $attempt/$maxRetries');
          await Future.delayed(Duration(seconds: attempt * 2));
        }

        final response = await _callAPI(prompt);
        return response;
      } on http.ClientException catch (e) {
        lastError = e;
        print('⚠️ Gemini network error: $e');
      } on Exception catch (e) {
        lastError = e;
        print('⚠️ Gemini error: $e');
      }
    }

    throw lastError ?? Exception('Gemini failed after $maxRetries retries');
  }

  Future<String> _callAPI(String prompt) async {
    final uri = Uri.parse('$_baseUrl?key=$apiKey');

    final response = await http
        .post(
      uri,
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
          'temperature': 0.2,
          'maxOutputTokens': 4000,
          'topP': 0.8,
          'topK': 10,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_NONE',
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_NONE',
          },
        ],
      }),
    )
        .timeout(timeout);

    if (response.statusCode != 200) {
      final error = _parseError(response.body);
      throw Exception('Gemini API error (${response.statusCode}): $error');
    }

    final data = jsonDecode(response.body);

    if (data['candidates'] == null || (data['candidates'] as List).isEmpty) {
      throw Exception('Empty response from Gemini');
    }

    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }

  String _parseError(String body) {
    try {
      final data = jsonDecode(body);
      if (data['error'] != null) {
        return data['error']['message'] ?? 'Unknown error';
      }
    } catch (_) {}
    return body;
  }

  @override
  Future<bool> testConnection() async {
    try {
      final response = await generate('Say "OK" in JSON: {"status": "OK"}');
      return response.contains('OK');
    } catch (e) {
      print('❌ Gemini connection test failed: $e');
      return false;
    }
  }
}