/// Pure progress rules; storage timestamps are converted at the repository edge.
class StudyProgress {
  const StudyProgress({
    required this.completed,
    required this.daily,
    required this.total,
    required this.target,
    required this.streak,
    required this.lastReset,
  });
  final int completed, daily, total, target, streak;
  final DateTime? lastReset;

  double get percent =>
      total <= 0 ? 0 : (completed / total * 100).clamp(0, 100).toDouble();

  StudyProgress forDay(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final last = lastReset;
    if (last != null &&
        last.year == now.year &&
        last.month == now.month &&
        last.day == now.day) {
      return this;
    }
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final keepStreak =
        last != null &&
        last.year == yesterday.year &&
        last.month == yesterday.month &&
        last.day == yesterday.day &&
        daily >= target;
    return StudyProgress(
      completed: completed,
      daily: 0,
      total: total,
      target: target,
      streak: keepStreak ? streak : 0,
      lastReset: today,
    );
  }

  StudyProgress complete({
    required bool firstCompletion,
    required DateTime now,
  }) {
    final current = forDay(now);
    final nextDaily = current.daily + 1;
    return StudyProgress(
      completed: current.completed + (firstCompletion ? 1 : 0),
      daily: nextDaily,
      total: total,
      target: target,
      streak:
          current.streak +
          (current.daily < target && nextDaily >= target ? 1 : 0),
      lastReset: current.lastReset,
    );
  }
}
