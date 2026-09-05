import 'package:flutter_test/flutter_test.dart';
import 'package:learn_english/domain/progress/study_progress.dart';

void main() {
  final today = DateTime(2026, 9, 5, 12);
  StudyProgress progress({int daily = 4, DateTime? lastReset}) => StudyProgress(
    completed: 10,
    daily: daily,
    total: 20,
    target: 5,
    streak: 3,
    lastReset: lastReset ?? today,
  );

  test(
    'first completion counts once and crossing daily goal adds one streak',
    () {
      final first = progress().complete(firstCompletion: true, now: today);
      expect(first.completed, 11);
      expect(first.daily, 5);
      expect(first.streak, 4);
      final replay = first.complete(firstCompletion: false, now: today);
      expect(replay.completed, 11);
      expect(replay.daily, 6);
      expect(replay.streak, 4);
      expect(replay.percent, closeTo(55, 0.000001));
    },
  );

  test('next day preserves a met streak and resets daily count', () {
    final next = progress(
      daily: 5,
      lastReset: DateTime(2026, 9, 4),
    ).forDay(today);
    expect(next.daily, 0);
    expect(next.streak, 3);
    expect(next.forDay(today).daily, 0);
  });

  test('missing yesterday or missing its goal resets streak', () {
    expect(progress(lastReset: DateTime(2026, 9, 4)).forDay(today).streak, 0);
    expect(
      progress(daily: 5, lastReset: DateTime(2026, 9, 3)).forDay(today).streak,
      0,
    );
  });

  test('completion resets a stale daily count even without visiting Home', () {
    final next = progress(
      daily: 5,
      lastReset: DateTime(2026, 9, 4),
    ).complete(firstCompletion: true, now: today);
    expect(next.daily, 1);
    expect(next.streak, 3);
  });

  test('empty catalogue produces a finite zero percentage', () {
    const empty = StudyProgress(
      completed: 0,
      daily: 0,
      total: 0,
      target: 5,
      streak: 0,
      lastReset: null,
    );
    expect(empty.percent, 0);
  });
}
