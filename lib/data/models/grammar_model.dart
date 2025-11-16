// models/grammar_model.dart
class GrammarTopic {
  final String id;
  final String title; // Cấp 1: "Các thì trong tiếng Anh"
  final List<GrammarSubTopic> subTopics;

  GrammarTopic({
    required this.id,
    required this.title,
    required this.subTopics,
  });

  // ✅ THÊM: Factory để parse JSON
  factory GrammarTopic.fromJson(Map<String, dynamic> json) {
    return GrammarTopic(
      id: json['id'] as String,
      title: json['title'] as String,
      subTopics: (json['subTopics'] as List<dynamic>)
          .map((dynamic item) => GrammarSubTopic.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GrammarSubTopic {
  final String id;
  final String title; // Cấp 2: "Thì hiện tại đơn"
  final Map<String, GrammarSection> sections; // Cấp 3: Key = "definition", Value = Section

  GrammarSubTopic({
    required this.id,
    required this.title,
    required this.sections,
  });

  // ✅ THÊM: Factory để parse JSON
  factory GrammarSubTopic.fromJson(Map<String, dynamic> json) {
    final Map<String, GrammarSection> parsedSections = {};
    (json['sections'] as Map<String, dynamic>).forEach((key, value) {
      parsedSections[key] = GrammarSection.fromJson(value as Map<String, dynamic>);
    });
    return GrammarSubTopic(
      id: json['id'] as String,
      title: json['title'] as String,
      sections: parsedSections,
    );
  }
}

class GrammarSection {
  final String title; // e.g., "Định nghĩa"
  final String content; // Nội dung chi tiết + ví dụ
  final List<String>? examples; // Danh sách ví dụ câu

  GrammarSection({
    required this.title,
    required this.content,
    this.examples,
  });

  // ✅ THÊM: Factory để parse JSON
  factory GrammarSection.fromJson(Map<String, dynamic> json) {
    return GrammarSection(
      title: json['title'] as String,
      content: json['content'] as String,
      examples: json['examples'] != null
          ? (json['examples'] as List<dynamic>).cast<String>().toList()
          : null,
    );
  }
}