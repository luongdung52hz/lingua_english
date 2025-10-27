class LessonModel {
  final String id;
  final String title;
  final String description;
  final String level; // "A1", "A2", "B1", "B2", "C1", "C2"
  final String skill; // "listening", "speaking", "reading", "writing"
  final String topic;
  final Map<String, dynamic> content; // Nội dung (audioUrl, text, quiz)
  final int duration;
  final int difficulty;

  LessonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.skill,
    required this.topic,
    required this.content,
    required this.duration,
    required this.difficulty,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json, String docId) {
    return LessonModel(
      id: docId,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      level: json['level'] ?? 'A1',
      skill: json['skill'] ?? 'listening',
      topic: json['topic'] ?? '',
      content: Map<String, dynamic>.from(json['content'] ?? {}),
      duration: json['duration'] ?? 0,
      difficulty: json['difficulty'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'level': level,
    'skill': skill,
    'topic':topic,
    'content': content,
    'duration': duration,
    'difficulty': difficulty,
  };
}