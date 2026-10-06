import 'dart:math';

import '../models/task.dart';
import '../services/sla_service.dart';
import '../services/storage_service.dart';

/// Filters shown as chips on the Task List.
enum TaskFilter {
  all('All'),
  todo('Todo'),
  inProgress('In Progress'),
  paused('Paused'),
  completed('Completed'),
  atRisk('At Risk'),
  overdue('Overdue');

  const TaskFilter(this.label);
  final String label;
}

enum TaskSort {
  deadline('Deadline (soonest first)'),
  priority('Priority (highest first)'),
  updated('Recently updated');

  const TaskSort(this.label);
  final String label;
}

enum Workload {
  available('Available', 0),
  light('Light', 1),
  balanced('Balanced', 2),
  focused('Focused', 3),
  overloaded('Overloaded', 4);

  const Workload(this.label, this.bars);
  final String label;
  final int bars;
}

class MemberStats {
  const MemberStats({
    required this.assigned,
    required this.completed,
    required this.active,
    required this.workload,
  });
  final int assigned;
  final int completed;
  final int active;
  final Workload workload;
}

/// Coordinates task behaviour: User Action → Controller → SQLite → memory
/// refresh → the calling screen runs `setState()` → UI rebuild.
class TaskController {
  TaskController({StorageService? storage, this.sla = const SlaService()})
    : _storage = storage ?? StorageService.instance;

  final StorageService _storage;

  /// SLA business rules (exposed so screens can show timeline details).
  final SlaService sla;
  final _random = Random();

  List<Task> _tasks = [];
  List<Task> get tasks => List.unmodifiable(_tasks);

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Future<void> loadTasks() async => _tasks = await _storage.getTasks();

  Future<void> refreshTasks() => loadTasks();

  Task? getTask(String id) {
    for (final t in _tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Commands
  // ---------------------------------------------------------------------------

  Future<Task> createTask({
    required String title,
    required String description,
    required String assignedTo,
    required Priority priority,
    required DateTime deadline,
  }) async {
    final now = DateTime.now();
    final task = Task(
      id: 't_${now.microsecondsSinceEpoch}_${_random.nextInt(1 << 16)}',
      title: title.trim(),
      description: description.trim(),
      assignedTo: assignedTo,
      priority: priority,
      status: TaskStatus.todo,
      createdAt: now,
      updatedAt: now,
      deadline: deadline,
      atRiskAt: sla.calculateAtRiskAt(now, deadline),
    );
    await _storage.insertTask(task);
    await refreshTasks();
    return task;
  }

  /// Saves edits from the form. Deadline changes recalculate atRiskAt and
  /// status changes go through the SLA pause/resume rules.
  Future<Task> updateTask(
    Task original, {
    required String title,
    required String description,
    required String assignedTo,
    required Priority priority,
    required DateTime deadline,
    required TaskStatus status,
  }) async {
    var task = original.copyWith(
      title: title.trim(),
      description: description.trim(),
      assignedTo: assignedTo,
      priority: priority,
    );
    task = sla.withDeadline(task, deadline);
    task = sla.transition(task, status);
    task = task.copyWith(updatedAt: DateTime.now());
    await _storage.updateTask(task);
    await refreshTasks();
    return task;
  }

  Future<Task> updateTaskStatus(Task task, TaskStatus status) async {
    final updated = sla.transition(task, status);
    await _storage.updateTask(updated);
    await refreshTasks();
    return updated;
  }

  Future<void> deleteTask(String id) async {
    await _storage.deleteTask(id);
    await refreshTasks();
  }

  Future<void> resetDemoData() async {
    await _storage.resetDemoData();
    await refreshTasks();
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  SlaStatus slaOf(Task task) => sla.calculateSlaStatus(task);

  Map<SlaStatus, int> get slaCounts {
    final counts = {for (final s in SlaStatus.values) s: 0};
    for (final t in _tasks) {
      counts[slaOf(t)] = counts[slaOf(t)]! + 1;
    }
    return counts;
  }

  int countByStatus(TaskStatus status) =>
      _tasks.where((t) => t.status == status).length;

  /// Share of tasks that are On Track or Completed.
  double get healthRatio {
    if (_tasks.isEmpty) return 1;
    final c = slaCounts;
    return (c[SlaStatus.onTrack]! + c[SlaStatus.completed]!) / _tasks.length;
  }

  /// Overdue then At Risk tasks, most urgent first.
  List<Task> get needsAttention {
    final list = _tasks.where((t) {
      final s = slaOf(t);
      return s == SlaStatus.overdue || s == SlaStatus.atRisk;
    }).toList();
    list.sort((a, b) {
      final sa = slaOf(a) == SlaStatus.overdue ? 0 : 1;
      final sb = slaOf(b) == SlaStatus.overdue ? 0 : 1;
      if (sa != sb) return sa - sb;
      return a.deadline.compareTo(b.deadline);
    });
    return list;
  }

  List<Task> recent(int limit) {
    final list = [..._tasks]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list.take(limit).toList();
  }

  List<Task> filtered({
    TaskFilter filter = TaskFilter.all,
    String query = '',
    TaskSort sort = TaskSort.deadline,
    String? Function(Task t)? assigneeName,
  }) {
    final q = query.trim().toLowerCase();
    final list = _tasks.where((t) {
      if (!_matchesFilter(t, filter)) return false;
      if (q.isEmpty) return true;
      return t.title.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q) ||
          (assigneeName?.call(t)?.toLowerCase().contains(q) ?? false);
    }).toList();

    switch (sort) {
      case TaskSort.deadline:
        list.sort((a, b) => a.deadline.compareTo(b.deadline));
      case TaskSort.priority:
        list.sort((a, b) {
          final p = b.priority.index - a.priority.index;
          return p != 0 ? p : a.deadline.compareTo(b.deadline);
        });
      case TaskSort.updated:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return list;
  }

  bool _matchesFilter(Task t, TaskFilter f) {
    switch (f) {
      case TaskFilter.all:
        return true;
      case TaskFilter.todo:
        return t.status == TaskStatus.todo;
      case TaskFilter.inProgress:
        return t.status == TaskStatus.inProgress;
      case TaskFilter.paused:
        return t.status == TaskStatus.paused;
      case TaskFilter.completed:
        return t.status == TaskStatus.completed;
      case TaskFilter.atRisk:
        return slaOf(t) == SlaStatus.atRisk;
      case TaskFilter.overdue:
        return slaOf(t) == SlaStatus.overdue;
    }
  }

  List<Task> tasksFor(String memberId) =>
      _tasks.where((t) => t.assignedTo == memberId).toList()
        ..sort((a, b) => a.deadline.compareTo(b.deadline));

  MemberStats statsFor(String memberId) {
    final mine = tasksFor(memberId);
    final done = mine.where((t) => t.isCompleted).length;
    final active = mine.where((t) => !t.isCompleted).toList();

    // Each open task adds load; urgency and high priority add extra weight.
    var load = 0.0;
    for (final t in active) {
      var weight = 1.0;
      final s = slaOf(t);
      if (s == SlaStatus.overdue || s == SlaStatus.atRisk) weight += 0.5;
      if (t.priority == Priority.high) weight += 0.5;
      load += weight;
    }
    final Workload workload;
    if (active.isEmpty) {
      workload = Workload.available;
    } else if (load < 1.5) {
      workload = Workload.light;
    } else if (load < 2) {
      workload = Workload.balanced;
    } else if (load < 3.5) {
      workload = Workload.focused;
    } else {
      workload = Workload.overloaded;
    }
    return MemberStats(
      assigned: mine.length,
      completed: done,
      active: active.length,
      workload: workload,
    );
  }
}
