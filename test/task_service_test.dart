import 'package:flutter_test/flutter_test.dart';
import 'package:sla_task_tracker_flutter/models/enums.dart';
import 'package:sla_task_tracker_flutter/models/exceptions.dart';
import 'package:sla_task_tracker_flutter/models/task.dart';
import 'package:sla_task_tracker_flutter/models/team_member.dart';
import 'package:sla_task_tracker_flutter/services/database_service.dart';
import 'package:sla_task_tracker_flutter/services/task_service.dart';

// Fake DatabaseService for testing TaskService logic without SQLite
class FakeDatabaseService implements DatabaseService {
  final Map<String, Task> _tasks = {};

  @override
  Future<List<Task>> getAllTasks() async => _tasks.values.toList();

  @override
  Future<Task?> getTaskById(String id) async => _tasks[id];

  @override
  Future<void> insertTask(Task task) async {
    _tasks[task.id] = task;
  }

  @override
  Future<void> updateTask(Task task) async {
    _tasks[task.id] = task;
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks.remove(id);
  }

  @override
  Future<List<TeamMember>> getAllMembers() async => [];

  @override
  Future<TeamMember?> getMemberById(String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TaskService SLA & Business Logic Tests', () {
    late FakeDatabaseService fakeDb;
    late TaskService taskService;
    late DateTime mockNow;
    
    late DateTime baseCreatedAt;
    late DateTime baseDeadline;

    setUp(() {
      fakeDb = FakeDatabaseService();
      
      // Start time at Jan 1, 2025
      mockNow = DateTime(2025, 1, 1, 12, 0); 
      taskService = TaskService(databaseService: fakeDb, clock: () => mockNow);
      
      baseCreatedAt = mockNow; 
      baseDeadline = baseCreatedAt.add(const Duration(days: 4)); // Jan 5, 12:00
    });

    test('T11: computeAtRiskAt formula (75%)', () {
      final expectedAtRiskAt = baseCreatedAt.add(const Duration(days: 3));
      final actualAtRiskAt = taskService.computeAtRiskAt(baseCreatedAt, baseDeadline);
      
      expect(actualAtRiskAt.isAtSameMomentAs(expectedAtRiskAt), isTrue);
    });

    test('T1: New task starts as On Track before atRiskAt', () async {
      final task = await taskService.createTask(
        title: 'Test', 
        assignedTo: 'u1', 
        priority: TaskPriority.low, 
        deadline: baseDeadline
      );

      // Advance clock by 1 day
      mockNow = baseCreatedAt.add(const Duration(days: 1)); 
      final sla = taskService.getSlaStatus(task, now: mockNow);
      expect(sla, equals(SlaStatus.onTrack));
    });

    test('T2 & T3: Task becomes At Risk exactly at threshold and after', () async {
      final task = await taskService.createTask(
        title: 'Test', 
        assignedTo: 'u1', 
        priority: TaskPriority.low, 
        deadline: baseDeadline
      );

      // Exactly at the threshold
      mockNow = task.atRiskAt;
      expect(taskService.getSlaStatus(task, now: mockNow), equals(SlaStatus.atRisk));

      // Just after
      mockNow = task.atRiskAt.add(const Duration(seconds: 1));
      expect(taskService.getSlaStatus(task, now: mockNow), equals(SlaStatus.atRisk));
    });

    test('T4: Task becomes Overdue past deadline', () async {
      final task = await taskService.createTask(
        title: 'Test', 
        assignedTo: 'u1', 
        priority: TaskPriority.low, 
        deadline: baseDeadline
      );

      mockNow = task.deadline.add(const Duration(seconds: 1));
      expect(taskService.getSlaStatus(task, now: mockNow), equals(SlaStatus.overdue));
    });

    test('T5: Completed task is always Completed SLA', () async {
      final task = await taskService.createTask(
        title: 'Test', 
        assignedTo: 'u1', 
        priority: TaskPriority.low, 
        deadline: baseDeadline
      );
      
      await taskService.startTask(task.id);
      final completedTask = await taskService.completeTask(task.id);

      mockNow = task.deadline.add(const Duration(days: 10));
      expect(taskService.getSlaStatus(completedTask, now: mockNow), equals(SlaStatus.completed));
    });

    test('T6: Pause freezes SLA clock', () async {
      final task = await taskService.createTask(
        title: 'Test', 
        assignedTo: 'u1', 
        priority: TaskPriority.low, 
        deadline: baseDeadline
      );
      await taskService.startTask(task.id);

      // Pause at day 2
      mockNow = baseCreatedAt.add(const Duration(days: 2));
      final pausedTask = await taskService.pauseTask(task.id);

      // Check SLA 10 days later
      mockNow = pausedTask.pausedAt!.add(const Duration(days: 10));
      expect(taskService.getSlaStatus(pausedTask, now: mockNow), equals(SlaStatus.onTrack));
    });

    test('T7 & T8: Resume shifts deadline and handles multiple pauses', () async {
      final task = await taskService.createTask(
        title: 'Test', 
        assignedTo: 'u1', 
        priority: TaskPriority.low, 
        deadline: baseDeadline
      );
      await taskService.startTask(task.id);

      // Pause exactly 1 day after creation
      mockNow = baseCreatedAt.add(const Duration(days: 1));
      await taskService.pauseTask(task.id);
      
      // Resume exactly 1 day after pause (duration = 1 day)
      mockNow = mockNow.add(const Duration(days: 1));
      final resumedTask = await taskService.resumeTask(task.id);
      
      expect(resumedTask.status, equals(TaskStatus.inProgress));
      expect(resumedTask.pausedAt, isNull);
      
      // The deadline should be shifted by 1 day
      final shift = resumedTask.deadline.difference(baseDeadline);
      expect(shift.inDays, equals(1));
    });

    test('T9: Deadline edit recalculates atRiskAt', () async {
      final task = await taskService.createTask(
        title: 'Test', 
        assignedTo: 'u1', 
        priority: TaskPriority.low, 
        deadline: baseDeadline
      );

      // Change deadline to 8 days total
      final newDeadline = baseCreatedAt.add(const Duration(days: 8)); 
      
      final updatedTask = await taskService.updateTaskFields(task.id, deadline: newDeadline);

      // 75% of 8 days = 6 days
      final expectedAtRiskAt = baseCreatedAt.add(const Duration(days: 6));
      expect(updatedTask.atRiskAt.isAtSameMomentAs(expectedAtRiskAt), isTrue);
    });

    test('T10: Deadline edit blocked while paused', () async {
      final task = await taskService.createTask(
        title: 'Test', 
        assignedTo: 'u1', 
        priority: TaskPriority.low, 
        deadline: baseDeadline
      );
      await taskService.startTask(task.id);
      await taskService.pauseTask(task.id);

      // Advance time but task is paused
      mockNow = baseCreatedAt.add(const Duration(days: 5));
      final newDeadline = mockNow.add(const Duration(days: 8));
      
      expect(
        () => taskService.updateTaskFields(task.id, deadline: newDeadline),
        throwsA(isA<ValidationException>()),
      );
    });

    test('T12: Starting a paused task fails (must use resume)', () async {
      final task = await taskService.createTask(
        title: 'Test', 
        priority: TaskPriority.low, 
        deadline: baseDeadline
      );
      await taskService.startTask(task.id);
      await taskService.pauseTask(task.id);
      
      expect(() => taskService.startTask(task.id), throwsA(isA<TaskServiceException>()));
    });

    test('T13: Edit overdue task without changing deadline', () async {
      final task = await taskService.createTask(
        title: 'Test', 
        priority: TaskPriority.low, 
        deadline: baseDeadline
      );
      
      mockNow = baseDeadline.add(const Duration(days: 1)); // Now overdue
      expect(taskService.getSlaStatus(task, now: mockNow), equals(SlaStatus.overdue));

      final updatedTask = await taskService.updateTaskFields(task.id, title: 'Updated Overdue');
      expect(updatedTask.title, equals('Updated Overdue'));
    });

    test('T14: Reject past deadlines on creation', () async {
      final pastDeadline = mockNow.subtract(const Duration(seconds: 1));
      
      expect(
        () => taskService.createTask(
          title: 'Test', 
          priority: TaskPriority.low, 
          deadline: pastDeadline
        ),
        throwsA(isA<ValidationException>())
      );
    });

    test('T15: Reject empty title on creation and update', () async {
      expect(
        () => taskService.createTask(
          title: '   ', 
          priority: TaskPriority.low, 
          deadline: baseDeadline
        ),
        throwsA(isA<ValidationException>())
      );

      final task = await taskService.createTask(
        title: 'Valid', 
        priority: TaskPriority.low, 
        deadline: baseDeadline
      );

      expect(
        () => taskService.updateTaskFields(task.id, title: ''),
        throwsA(isA<ValidationException>())
      );
    });

    test('T16: Cannot edit a completed task', () async {
      final task = await taskService.createTask(
        title: 'Test', 
        priority: TaskPriority.low, 
        deadline: baseDeadline
      );
      
      await taskService.startTask(task.id);
      await taskService.completeTask(task.id);

      expect(
        () => taskService.updateTaskFields(task.id, title: 'Nope'),
        throwsA(isA<TaskServiceException>())
      );
    });
  });
}
