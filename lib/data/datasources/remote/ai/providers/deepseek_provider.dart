import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';

/// DeepSeek Provider - OpenAI-compatible API
/// Docs: https://api-docs.deepseek.com/
class DeepSeekProvider implements AIProvider {
  @override
  final String apiKey;

  @override
  final Duration timeout;

  @override
  final int maxRetries;

  // DeepSeek API endpoint (OpenAI-compatible)
  static const String _baseUrl = 'https://api.deepseek.com/v1/chat/completions';

  final String model;

  DeepSeekProvider({
    required this.apiKey,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 2,
    this.model = 'deepseek-chat',
  });

  @override
  String get name => 'DeepSeek';

  @override
  Future<String> generate(String prompt) async {
    Exception? lastError;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          print('🔄 DeepSeek retry $attempt/$maxRetries');
          await Future.delayed(Duration(seconds: attempt * 2));
        }

        final response = await _callAPI(prompt);
        return response;
      } on http.ClientException catch (e) {
        lastError = e;
        print('⚠️ DeepSeek network error: $e');
      } on Exception catch (e) {
        lastError = e;
        print('⚠️ DeepSeek error: $e');
      }
    }

    throw lastError ?? Exception('DeepSeek failed after $maxRetries retries');
  }

  Future<String> _callAPI(String prompt) async {
    final response = await http
        .post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content':
            'You are an English teacher. Return ONLY valid JSON responses without markdown formatting.',
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.2,
        'max_tokens': 2048,
        'top_p': 0.8,
        'frequency_penalty': 0,
        'presence_penalty': 0,
        'stream': false,
      }),
    )
        .timeout(timeout);

    if (response.statusCode != 200) {
      final error = _parseError(response.body);
      throw Exception('DeepSeek API error (${response.statusCode}): $error');
    }

    final data = jsonDecode(response.body);

    if (data['choices'] == null || (data['choices'] as List).isEmpty) {
      throw Exception('Empty response from DeepSeek');
    }

    return data['choices'][0]['message']['content'] as String;
  }

  String _parseError(String body) {
    try {
      final data = jsonDecode(body);
      if (data['error'] != null) {
        final error = data['error'];
        return '${error['type'] ?? 'error'}: ${error['message'] ?? 'Unknown error'}';
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
      print(' DeepSeek connection test failed: $e');
      return false;
    }
  }
}

/// Pricing info (tham khảo)
/// DeepSeek-Chat: $0.14/1M input tokens, $0.28/1M output tokens
/// Rẻ hơn Gemini (~70% cheaper) và GPT-4 (~95% cheaper)