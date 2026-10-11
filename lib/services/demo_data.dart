import '../models/enums.dart';
import '../models/task.dart';
import 'database_service.dart';
import 'task_service.dart';

/// Inserts four demo tasks, one for each SLA state, the first time the app
/// runs (when the database has no tasks). Dates are relative to now, so the
/// states are correct whenever the app is installed.
///
/// createTask rightly refuses past deadlines, so the Overdue, At Risk and
/// Completed tasks are inserted straight through DatabaseService.
/// To see the seed again, uninstall the app so the database is recreated.
Future<void> seedDemoTasksIfEmpty() async {
  final db = DatabaseService();
  final service = TaskService();

  if ((await db.getAllTasks()).isNotEmpty) return;
  final members = await db.getAllMembers();
  if (members.length < 4) return;

  final now = DateTime.now();

  Task build({
    required String id,
    required String title,
    required String description,
    required int member,
    required TaskPriority priority,
    required TaskStatus status,
    required DateTime created,
    required DateTime deadline,
    DateTime? pausedAt,
  }) {
    return Task(
      id: id,
      title: title,
      description: description,
      assignedTo: members[member].id,
      priority: priority,
      status: status,
      createdAt: created,
      updatedAt: pausedAt ?? created,
      deadline: deadline,
      atRiskAt: service.computeAtRiskAt(created, deadline),
      pausedAt: pausedAt,
    );
  }

  // Overdue: in progress, deadline passed.
  await db.insertTask(build(
    id: 'demo_task_1',
    title: 'Resolve payment retry failures',
    description:
        'Investigate failed retry attempts in the checkout service and deploy a verified fix before the next billing cycle.',
    member: 0,
    priority: TaskPriority.high,
    status: TaskStatus.inProgress,
    created: now.subtract(const Duration(hours: 8)),
    deadline: now.subtract(const Duration(minutes: 30)),
  ));

  // At Risk: paused after its At Risk time, so the SLA clock is frozen.
  await db.insertTask(build(
    id: 'demo_task_2',
    title: 'Ship onboarding analytics',
    description:
        'Add the approved onboarding events and confirm that each step is represented in the growth dashboard.',
    member: 1,
    priority: TaskPriority.medium,
    status: TaskStatus.paused,
    created: now.subtract(const Duration(hours: 10)),
    deadline: now.add(const Duration(hours: 2)),
    pausedAt: now.subtract(const Duration(minutes: 20)),
  ));

  // Completed.
  await db.insertTask(build(
    id: 'demo_task_3',
    title: 'API rate limit alerts',
    description: 'Alert the team when any client reaches 80 percent of its rate limit.',
    member: 2,
    priority: TaskPriority.low,
    status: TaskStatus.completed,
    created: now.subtract(const Duration(days: 2)),
    deadline: now.subtract(const Duration(days: 1)),
  ));

  // On Track: not started, deadline in two days.
  await db.insertTask(build(
    id: 'demo_task_4',
    title: 'Review accessibility fixes',
    description: 'Check contrast, labels and focus order on the updated screens.',
    member: 3,
    priority: TaskPriority.low,
    status: TaskStatus.todo,
    created: now.subtract(const Duration(hours: 1)),
    deadline: now.add(const Duration(days: 2)),
  ));
}
