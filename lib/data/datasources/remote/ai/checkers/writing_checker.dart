import 'dart:convert';
import '../providers/ai_provider.dart';
import '../models/writing_result.dart';

/// Writing Checker - Đánh giá writing với AI
class WritingChecker {
  final AIProvider provider;

  WritingChecker(this.provider);

  Future<WritingResult> checkWriting({
    required String text,
    required String prompt,
    required List<String> requirements,
    int? minWords,
    int? maxWords,
  }) async {
    final promptStr = _buildPrompt(text, prompt, requirements, minWords, maxWords);

    try {
      final response = await provider.generate(promptStr);
      print('🔧 RAW AI RESPONSE: $response'); // DEBUG

      final jsonStr = _extractJson(response);
      print('🔧 EXTRACTED JSON: $jsonStr'); // DEBUG

      if (jsonStr.isEmpty) {
        throw Exception('No valid JSON found in response');
      }

      final jsonMap = jsonDecode(jsonStr);
      print('🔧 PARSED JSON KEYS: ${jsonMap.keys}'); // DEBUG

      return WritingResult.fromJson(jsonMap);
    } catch (e) {
      print('❌ Error checking writing: $e');
      return WritingResult.error('AI chấm điểm thất bại: ${e.toString()}');
    }
  }

  String _buildPrompt(
      String text,
      String prompt,
      List<String> requirements,
      int? minWords,
      int? maxWords,
      ) {
    return '''
Bạn là giáo viên tiếng Anh. Hãy đánh giá bài viết của học sinh và trả về kết quả bằng tiếng Việt.

CHỦ ĐỀ: "$prompt"

BÀI VIẾT CỦA HỌC SINH: "$text"

YÊU CẦU: 
${requirements.map((r) => '- $r').join('\n')}

SỐ TỐI THIỂU: ${minWords ?? 'Không yêu cầu'}
SỐ TỐI ĐA: ${maxWords ?? 'Không yêu cầu'}

Phân tích và trả về DUY NHẤT JSON (không markdown, không text thừa):
{
  "score": 85,
  "grammar_score": 80,
  "vocabulary_score": 85,
  "structure_score": 90,
  "content_score": 85,
  "feedback": "Cấu trúc bài tốt, nhưng cần cải thiện ngữ pháp...",
  "strengths": ["Từ vựng phong phú", "Ý tưởng rõ ràng"],
  "improvements": ["Sửa lỗi thì", "Thêm từ nối"],
  "grammar_errors": [
    {
      "error": "I go to school yesterday",
      "correction": "I went to school yesterday",
      "explanation": "Dùng thì quá khứ đơn cho hành động đã hoàn thành"
    }
  ],
  "vocabulary_suggestions": [
    {
      "word": "good",
      "better": "excellent",
      "context": "Dùng từ mạnh hơn để nhấn mạnh"
    }
  ],
  "word_count": 156,
  "meets_requirements": true
}

Quy tắc:
1. score = trung bình của grammar_score, vocabulary_score, structure_score, content_score
2. grammar_errors = tối đa 5 lỗi quan trọng với sửa chữa/giải thích
3. vocabulary_suggestions = 3-5 gợi ý từ vựng tốt hơn
4. meets_requirements = true nếu đáp ứng số từ và yêu cầu
5. Đưa ra nhận xét xây dựng bằng TIẾNG VIỆT
6. Giải thích lỗi ngữ pháp bằng TIẾNG VIỆT
7. Gợi ý từ vựng giải thích bằng TIẾNG VIỆT
8. Ưu điểm và cần cải thiện viết bằng TIẾNG VIỆT

Lưu ý quan trọng:
- Tất cả feedback, explanations, strengths, improvements phải bằng TIẾNG VIỆT
- Giải thích dễ hiểu cho học sinh Việt Nam
- Dùng từ ngữ thân thiện, khích lệ
- Chỉ ra lỗi cụ thể và cách sửa
''';
  }

  String _extractJson(String response) {
    print('🔧 Raw AI Response: ${response.length} characters');

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
      print('❌ JSON extraction failed - firstBrace: $firstBrace, lastBrace: $lastBrace');
      print('❌ Cleaned response: $cleaned');
      throw Exception('No valid JSON object found in response');
    }

    final jsonStr = cleaned.substring(firstBrace, lastBrace + 1);
    print('✅ JSON extracted: ${jsonStr.length} characters');

    return jsonStr;
  }
}