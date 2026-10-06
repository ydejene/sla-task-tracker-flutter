import '../models/task.dart';
import '../utils/constants.dart';

/// Pure SLA business rules. Contains no UI or database code so it can be
/// unit-tested and explained in isolation.
///
/// Every method that depends on the current time accepts an optional [now]
/// so tests can pin the clock.
class SlaService {
  const SlaService({this.threshold = AppConstants.atRiskThreshold});

  /// Fraction of the task lifecycle after which a task becomes At Risk.
  final double threshold;

  /// atRiskAt = createdAt + (deadline - createdAt) × threshold
  ///
  /// Calculated once when a task is created (or its deadline is edited) and
  /// stored, so normal display only compares timestamps.
  DateTime calculateAtRiskAt(DateTime createdAt, DateTime deadline) {
    final total = deadline.difference(createdAt);
    final offset = Duration(
      microseconds: (total.inMicroseconds * threshold).round(),
    );
    return createdAt.add(offset);
  }

  /// Decision rules (order matters):
  ///   1. Completed status          → Completed
  ///   2. now > deadline            → Overdue
  ///   3. now >= atRiskAt           → At Risk
  ///   4. otherwise                 → On Track
  ///
  /// While a task is paused its SLA clock is frozen, so it is evaluated at
  /// the moment it was paused rather than the current time.
  SlaStatus calculateSlaStatus(Task task, {DateTime? now}) {
    if (task.status == TaskStatus.completed) return SlaStatus.completed;
    final at = task.pausedAt ?? now ?? DateTime.now();
    if (at.isAfter(task.deadline)) return SlaStatus.overdue;
    if (!at.isBefore(task.atRiskAt)) return SlaStatus.atRisk;
    return SlaStatus.onTrack;
  }

  /// pausedDuration = now - pausedAt
  Duration calculatePausedDuration(DateTime pausedAt, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(pausedAt);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Starts a pause: records pausedAt = now.
  Task applyPause(Task task, {DateTime? now}) {
    final at = now ?? DateTime.now();
    return task.copyWith(
      status: TaskStatus.paused,
      pausedAt: at,
      updatedAt: at,
    );
  }

  /// Ends a pause: shifts deadline and atRiskAt forward by the paused
  /// duration and clears pausedAt.
  Task applyResume(Task task, TaskStatus nextStatus, {DateTime? now}) {
    final at = now ?? DateTime.now();
    if (task.pausedAt == null) {
      return task.copyWith(status: nextStatus, updatedAt: at);
    }
    final paused = calculatePausedDuration(task.pausedAt!, now: at);
    return task.copyWith(
      status: nextStatus,
      deadline: task.deadline.add(paused),
      atRiskAt: task.atRiskAt.add(paused),
      clearPausedAt: true,
      updatedAt: at,
    );
  }

  /// Moves a task to [next], applying pause/resume rules when the task
  /// enters or leaves the Paused state.
  Task transition(Task task, TaskStatus next, {DateTime? now}) {
    if (task.status == next) return task;
    if (next == TaskStatus.paused) return applyPause(task, now: now);
    if (task.status == TaskStatus.paused) {
      return applyResume(task, next, now: now);
    }
    return task.copyWith(status: next, updatedAt: now ?? DateTime.now());
  }

  /// Recalculates atRiskAt when a deadline is edited.
  Task withDeadline(Task task, DateTime deadline) {
    if (deadline == task.deadline) return task;
    return task.copyWith(
      deadline: deadline,
      atRiskAt: calculateAtRiskAt(task.createdAt, deadline),
    );
  }

  /// Fraction (0–1) of the planned lifecycle that has elapsed.
  double lifecycleProgress(Task task, {DateTime? now}) {
    final at = task.pausedAt ?? now ?? DateTime.now();
    final total = task.deadline.difference(task.createdAt).inSeconds;
    if (total <= 0) return 1;
    final elapsed = at.difference(task.createdAt).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
