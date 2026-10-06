import 'package:flutter_test/flutter_test.dart';
import 'package:sla_task_tracker_flutter/models/task.dart';
import 'package:sla_task_tracker_flutter/services/sla_service.dart';

void main() {
  const sla = SlaService();
  final created = DateTime(2026, 5, 20, 9);
  final deadline = DateTime(2026, 5, 24, 9); // 4-day lifecycle

  Task task({TaskStatus status = TaskStatus.inProgress, DateTime? pausedAt}) {
    return Task(
      id: 't1',
      title: 'Test task',
      description: '',
      assignedTo: 'm1',
      priority: Priority.medium,
      status: status,
      createdAt: created,
      updatedAt: created,
      deadline: deadline,
      atRiskAt: sla.calculateAtRiskAt(created, deadline),
      pausedAt: pausedAt,
    );
  }

  group('calculateAtRiskAt', () {
    test('is 75% of the lifecycle after creation', () {
      expect(
        sla.calculateAtRiskAt(created, deadline),
        DateTime(2026, 5, 23, 9),
      );
    });

    test('scales with short tasks', () {
      final start = DateTime(2026, 5, 20, 9);
      final end = DateTime(2026, 5, 20, 11); // 2 hours
      expect(sla.calculateAtRiskAt(start, end), DateTime(2026, 5, 20, 10, 30));
    });
  });

  group('calculateSlaStatus', () {
    test('future deadline before threshold → On Track', () {
      expect(
        sla.calculateSlaStatus(task(), now: DateTime(2026, 5, 21)),
        SlaStatus.onTrack,
      );
    });

    test('threshold reached → At Risk', () {
      expect(
        sla.calculateSlaStatus(task(), now: DateTime(2026, 5, 23, 9)),
        SlaStatus.atRisk,
      );
    });

    test('deadline passed and incomplete → Overdue', () {
      expect(
        sla.calculateSlaStatus(task(), now: DateTime(2026, 5, 25)),
        SlaStatus.overdue,
      );
    });

    test('completed stays Completed even after the deadline', () {
      final t = task(status: TaskStatus.completed);
      expect(
        sla.calculateSlaStatus(t, now: DateTime(2026, 6, 1)),
        SlaStatus.completed,
      );
    });

    test('paused task is evaluated at pausedAt (clock frozen)', () {
      final t = task(
        status: TaskStatus.paused,
        pausedAt: DateTime(2026, 5, 21),
      );
      expect(
        sla.calculateSlaStatus(t, now: DateTime(2026, 5, 30)),
        SlaStatus.onTrack,
      );
    });
  });

  group('pause / resume', () {
    test('pause records pausedAt', () {
      final now = DateTime(2026, 5, 21, 9);
      final paused = sla.applyPause(task(), now: now);
      expect(paused.status, TaskStatus.paused);
      expect(paused.pausedAt, now);
    });

    test('resume shifts deadline and atRiskAt by paused duration', () {
      final pausedAt = DateTime(2026, 5, 21, 9);
      final resumeAt = DateTime(2026, 5, 22, 15); // paused 30h
      final paused = sla.applyPause(task(), now: pausedAt);
      final resumed = sla.transition(
        paused,
        TaskStatus.inProgress,
        now: resumeAt,
      );

      expect(resumed.status, TaskStatus.inProgress);
      expect(resumed.pausedAt, isNull);
      expect(resumed.deadline, deadline.add(const Duration(hours: 30)));
      expect(
        resumed.atRiskAt,
        DateTime(2026, 5, 23, 9).add(const Duration(hours: 30)),
      );
    });

    test('completing a paused task also clears the pause', () {
      final paused = sla.applyPause(task(), now: DateTime(2026, 5, 21));
      final done = sla.transition(
        paused,
        TaskStatus.completed,
        now: DateTime(2026, 5, 22),
      );
      expect(done.pausedAt, isNull);
      expect(sla.calculateSlaStatus(done), SlaStatus.completed);
    });

    test('paused duration is never negative', () {
      final d = sla.calculatePausedDuration(
        DateTime(2026, 5, 22),
        now: DateTime(2026, 5, 21),
      );
      expect(d, Duration.zero);
    });
  });

  group('deadline edits', () {
    test('changing the deadline recalculates atRiskAt', () {
      final newDeadline = DateTime(2026, 5, 28, 9); // 8-day lifecycle
      final edited = sla.withDeadline(task(), newDeadline);
      expect(edited.deadline, newDeadline);
      expect(edited.atRiskAt, DateTime(2026, 5, 26, 9));
    });
  });

  group('model mapping', () {
    test('Task survives a toMap/fromMap round trip', () {
      final t = task(
        status: TaskStatus.paused,
        pausedAt: DateTime(2026, 5, 21),
      );
      final copy = Task.fromMap(t.toMap());
      expect(copy.status, t.status);
      expect(copy.deadline, t.deadline);
      expect(copy.atRiskAt, t.atRiskAt);
      expect(copy.pausedAt, t.pausedAt);
      expect(copy.assignedTo, t.assignedTo);
    });
  });
}
