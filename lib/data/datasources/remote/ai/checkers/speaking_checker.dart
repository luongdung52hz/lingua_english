import 'dart:convert';
import '../providers/ai_provider.dart';
import '../models/speaking_result.dart';

/// Speaking Checker - Đánh giá speaking với AI
class SpeakingChecker {
  final AIProvider provider;

  SpeakingChecker(this.provider);

  Future<SpeakingResult> checkSpeaking({ // FIXED: Renamed from 'check' to 'checkSpeaking' to match AIService call
    required String transcript,
    required String expectedContent,
    required List<String> targetWords,
  }) async {
    final prompt = _buildPrompt(transcript, expectedContent, targetWords);

    try {
      final response = await provider.generate(prompt);
      final jsonStr = _extractJson(response);

      if (jsonStr.isEmpty) {
        throw Exception('No valid JSON found in response');
      }

      return SpeakingResult.fromJson(jsonDecode(jsonStr));
    } catch (e) {
      print('❌ Error checking speaking: $e');
      return SpeakingResult.error('AI check failed: ${e.toString()}');
    }
  }

  String _buildPrompt(
      String transcript,
      String expectedContent,
      List<String> targetWords,
      ) {
    return '''
You are an English pronunciation teacher. Evaluate the student's speaking performance.

TRANSCRIPT (what student said): "$transcript"

EXPECTED CONTENT (what student should say): "$expectedContent"

TARGET WORDS (words to practice): ${targetWords.join(', ')}

Analyze and return ONLY valid JSON (no markdown, no extra text):
{
  "score": 85,
  "pronunciation_score": 80,
  "fluency_score": 85,
  "accuracy_score": 90,
  "feedback": "Good pronunciation, but need to improve...",
  "strengths": ["Clear pronunciation", "Good pace"],
  "improvements": ["Practice 'th' sound", "More intonation variety"],
  "detected_words": ["cat", "bat", "mat"],
  "missing_words": ["hat"]
}

Rules:
1. score = average of pronunciation_score, fluency_score, accuracy_score
2. detected_words = target words found in transcript
3. missing_words = target words NOT in transcript
4. Give constructive feedback in English
''';
  }

  /// Extract JSON from response (handle markdown code blocks)
  String _extractJson(String response) {
    String cleaned = response.trim();

    // Remove markdown: ```json\n{...}\n``` or ```\n{...}\n```
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned
          .replaceFirst('```json', '')
          .replaceFirst(RegExp(r'```$'), '')
          .trim();
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst('```', '')
          .replaceFirst(RegExp(r'```$'), '')
          .trim();
    }

    // Find first { and last }
    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');

    if (firstBrace == -1 || lastBrace == -1 || firstBrace >= lastBrace) {
      throw Exception('No valid JSON object found in response: $response');
    }

    return cleaned.substring(firstBrace, lastBrace + 1);
  }
}