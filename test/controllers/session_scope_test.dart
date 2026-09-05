import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:learn_english/app/di/dependency_injection.dart';
import 'package:learn_english/data/models/lesson_model.dart';
import 'package:learn_english/data/repositories/lesson_repository.dart';
import 'package:learn_english/presentation/controllers/lesson_controller.dart';

class SessionLessons implements LessonRepository {
  final stream = StreamController<List<LessonModel>>.broadcast();
  @override
  Stream<List<LessonModel>> getLessonsStream(
    String level,
    String skill, {
    String? topic,
  }) => stream.stream;
  @override
  Future<Map<String, int>> getProgressStats(
    String level,
    String skill, {
    String? topic,
  }) async => {'total': 0, 'completed': 0};
  @override
  Future<List<String>> getTopicsByLevelAndSkill(
    String level,
    String skill,
  ) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'session reset disposes live controllers and recreates clean state',
    () async {
      final repository = SessionLessons();
      getIt.registerSingleton<LessonRepository>(repository);
      await resetSessionControllers();
      final first = Get.find<LearnController>();
      await Future<void>.delayed(Duration.zero);
      first.completedLessons.value = 99;
      expect(repository.stream.hasListener, isTrue);
      await resetSessionControllers();
      expect(first.isClosed, isTrue);
      expect(repository.stream.hasListener, isFalse);
      final second = Get.find<LearnController>();
      expect(identical(first, second), isFalse);
      expect(second.completedLessons.value, 0);
      await Future<void>.delayed(Duration.zero);
      Get.reset();
      await getIt.reset();
      await repository.stream.close();
    },
  );
}
