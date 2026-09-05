import 'dart:async';
import 'package:get/get.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../data/models/lesson_model.dart';

class LearnController extends GetxController {
  LearnController({required LessonRepository repository}) : _repo = repository;
  final LessonRepository _repo;
  StreamSubscription<List<LessonModel>>? _lessonsSubscription;
  int _request = 0;

  final lessons = <LessonModel>[].obs;
  final totalLessons = 0.obs;
  final completedLessons = 0.obs;
  final currentLevel = 'A1'.obs;
  final currentSkill = 'listening'.obs;
  final currentLesson = Rx<LessonModel?>(null);
  final topics = <String>[].obs;
  final currentTopic = ''.obs;
  final isLoading = false.obs;
  final error = RxnString();
  final levels = const ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  final skills = const ['listening', 'speaking', 'reading', 'writing'];

  @override
  void onInit() {
    super.onInit();
    loadLessons(currentLevel.value, currentSkill.value);
  }

  Future<void> loadLessons(String level, String skill) =>
      _load(level, skill, null, reloadTopics: true);

  Future<void> loadLessonsByTopic(String level, String skill, String? topic) =>
      _load(level, skill, topic, reloadTopics: false);

  Future<void> _load(
    String level,
    String skill,
    String? topic, {
    required bool reloadTopics,
  }) async {
    final request = ++_request;
    currentLevel.value = level;
    currentSkill.value = skill;
    currentTopic.value = topic ?? '';
    isLoading.value = true;
    error.value = null;
    lessons.clear();
    completedLessons.value = 0;
    totalLessons.value = 0;
    final previous = _lessonsSubscription;
    _lessonsSubscription = null;
    await previous?.cancel();
    if (isClosed || request != _request) return;
    try {
      _lessonsSubscription = _repo
          .getLessonsStream(level, skill, topic: topic)
          .listen(
            (data) {
              if (isClosed || request != _request) return;
              lessons.assignAll(data);
            },
            onError: (Object value) {
              if (!isClosed && request == _request)
                error.value = value.toString();
            },
          );
      final results = await Future.wait<Object>([
        _repo.getProgressStats(level, skill, topic: topic),
        if (reloadTopics) _repo.getTopicsByLevelAndSkill(level, skill),
      ]);
      if (isClosed || request != _request) return;
      final stats = results.first as Map<String, int>;
      completedLessons.value = stats['completed'] ?? 0;
      totalLessons.value = stats['total'] ?? 0;
      if (reloadTopics) topics.assignAll(results[1] as List<String>);
    } catch (value) {
      if (!isClosed && request == _request) error.value = value.toString();
    } finally {
      if (!isClosed && request == _request) isLoading.value = false;
    }
  }

  Future<void> startLesson(LessonModel lesson) => _repo.startLesson(
    lesson.id,
    lesson.level,
    lesson.skill,
    topic: lesson.topic,
  );

  Future<void> completeLesson(
    LessonModel lesson,
    int score,
    int timeSpent,
  ) async {
    await _repo.completeLesson(lesson.id, score, timeSpent);
    if (!isClosed) await loadLessons(lesson.level, lesson.skill);
  }

  Future<LessonModel?> loadLessonById(String lessonId) async {
    final lesson = await _repo.getLessonById(lessonId);
    if (!isClosed) currentLesson.value = lesson;
    return lesson;
  }

  Future<void> startLessonById(String lessonId) async {
    final lesson = await loadLessonById(lessonId);
    if (lesson != null && !isClosed) await startLesson(lesson);
  }

  void changeLevel(String level) =>
      unawaited(loadLessons(level, currentSkill.value));
  void changeSkill(String skill) =>
      unawaited(loadLessons(currentLevel.value, skill));

  @override
  void onClose() {
    _request++;
    _lessonsSubscription?.cancel();
    super.onClose();
  }
}
