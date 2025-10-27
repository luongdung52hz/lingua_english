import 'deepseek_provider.dart';
import 'gemini_provider.dart';

/// Interface cho AI providers
/// Mọi provider (Gemini, DeepSeek, Claude, GPT) đều implement interface này
abstract class AIProvider {
  /// API key của provider
  String get apiKey;

  /// Timeout cho mỗi request
  Duration get timeout;

  /// Max retries khi fail
  int get maxRetries;

  /// Gọi AI với prompt và trả về raw response
  Future<String> generate(String prompt);

  /// Test connection với provider
  Future<bool> testConnection();

  /// Get provider name
  String get name;

}

/// Enum để chọn provider
enum AIProviderType {
  gemini,
  deepseek,
}

/// Factory để tạo provider
class AIProviderFactory {
  static AIProvider create({
    required AIProviderType type,
    required String apiKey,
    Duration? timeout,
    int? maxRetries,
  }) {
    switch (type) {
      case AIProviderType.gemini:
        return GeminiProvider(
          apiKey: apiKey,
          timeout: timeout ?? const Duration(seconds: 30),
          maxRetries: maxRetries ?? 2,
        );
      case AIProviderType.deepseek:
        return DeepSeekProvider(
          apiKey: apiKey,
          timeout: timeout ?? const Duration(seconds: 30),
          maxRetries: maxRetries ?? 2,
        );
    }
  }
}