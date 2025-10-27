class ProgressModel {
  final String lessonId;
  final bool completed;
  final int score;
  final int timeSpent;
  final String level;
  final String skill;

  ProgressModel({
    required this.lessonId,
    required this.completed,
    required this.score,
    required this.timeSpent,
    required this.level,
    required this.skill,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      lessonId: json['lessonId'] ?? '',
      completed: json['completed'] ?? false,
      score: json['score'] ?? 0,
      timeSpent: json['timeSpent'] ?? 0,
      level: json['level'] ?? 'A1',
      skill: json['skill'] ?? 'listening',
    );
  }

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'completed': completed,
    'score': score,
    'timeSpent': timeSpent,
    'level': level,
    'skill': skill,
  };
}