import 'checkers/speaking_checker.dart';
import 'providers/ai_provider.dart';
import 'checkers/writing_checker.dart';
import 'models/speaking_result.dart';
import 'models/writing_result.dart';


class AIService {
  final AIProvider provider;
  late final SpeakingChecker _speakingChecker;
  late final WritingChecker _writingChecker;

  AIService({required this.provider, required String apiKey}) {
    _speakingChecker = SpeakingChecker(provider);
    _writingChecker = WritingChecker(provider);
  }

  /// Factory constructor với provider type
  factory AIService.create({
    required AIProviderType providerType,
    required String apiKey,
    Duration? timeout,
    int? maxRetries,
  }) {
    final provider = AIProviderFactory.create(
      type: providerType,
      apiKey: apiKey,
      timeout: timeout,
      maxRetries: maxRetries,
    );
    return AIService(apiKey: '', provider: provider );
  }

  /// Check Speaking
  Future<SpeakingResult> checkSpeaking({
    required String transcript,
    required String expectedContent,
    required List<String> targetWords,
  }) async {
    return await _speakingChecker.checkSpeaking(
      transcript: transcript,
      expectedContent: expectedContent,
      targetWords: targetWords,
    );
  }

  /// Check Writing
  Future<WritingResult> checkWriting({
    required String text,
    required String prompt,
    required List<String> requirements,
    int? minWords,
    int? maxWords,
  }) async {
    return await _writingChecker.checkWriting(
      text: text,
      prompt: prompt,
      requirements: requirements,
      minWords: minWords,
      maxWords: maxWords,
    );
  }
}