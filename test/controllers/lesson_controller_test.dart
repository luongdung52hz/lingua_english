import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn_english/data/models/lesson_model.dart';
import 'package:learn_english/data/repositories/lesson_repository.dart';
import 'package:learn_english/presentation/controllers/lesson_controller.dart';

class FakeLessons implements LessonRepository {
  final streams = <String, StreamController<List<LessonModel>>>{};
  final stats = <String, Completer<Map<String, int>>>{};
  @override
  Stream<List<LessonModel>> getLessonsStream(
    String level,
    String skill, {
    String? topic,
  }) => (streams[level] ??= StreamController<List<LessonModel>>()).stream;
  @override
  Future<Map<String, int>> getProgressStats(
    String level,
    String skill, {
    String? topic,
  }) => (stats[level] ??= Completer<Map<String, int>>()).future;
  @override
  Future<List<String>> getTopicsByLevelAndSkill(
    String level,
    String skill,
  ) async => [level];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'switching filters cancels prior stream and ignores stale responses',
    () async {
      final repository = FakeLessons();
      final controller = LearnController(repository: repository);
      final first = controller.loadLessons('A1', 'reading');
      await Future<void>.delayed(Duration.zero);
      expect(repository.streams['A1']!.hasListener, isTrue);
      final second = controller.loadLessons('B1', 'reading');
      await Future<void>.delayed(Duration.zero);
      expect(repository.streams['A1']!.hasListener, isFalse);
      repository.stats['B1']!.complete({'total': 40, 'completed': 3});
      await second;
      repository.stats['A1']!.complete({'total': 20, 'completed': 9});
      await first;
      expect(controller.currentLevel.value, 'B1');
      expect(controller.completedLessons.value, 3);
      expect(controller.totalLessons.value, 40);
      expect(controller.topics, ['B1']);
      controller.onDelete();
      expect(repository.streams['B1']!.hasListener, isFalse);
      for (final stream in repository.streams.values) {
        await stream.close();
      }
    },
  );
}
