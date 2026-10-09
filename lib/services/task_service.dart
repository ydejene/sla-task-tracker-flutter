import 'package:uuid/uuid.dart';

import '../models/enums.dart';
import '../models/exceptions.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import 'database_service.dart';

class TaskService {
  final DatabaseService _db;
  final DateTime Function() _clock;
  final Uuid _uuid = const Uuid();

  TaskService({DatabaseService? databaseService, DateTime Function()? clock})
      : _db = databaseService ?? DatabaseService(),
        _clock = clock ?? (() => DateTime.now());

  // --- Reads ---

  Future<List<Task>> getAllTasks() async {
    return await _db.getAllTasks();
  }

  Future<Task?> getTaskById(String id) async {
    return await _db.getTaskById(id);
  }

  Future<List<TeamMember>> getAllMembers() async {
    return await _db.getAllMembers();
  }

  Future<TeamMember?> getMemberById(String id) async {
    return await _db.getMemberById(id);
  }

  // --- SLA Logic ---

  DateTime computeAtRiskAt(DateTime createdAt, DateTime deadline) {
    if (deadline.isBefore(createdAt) || deadline.isAtSameMomentAs(createdAt)) {
      return deadline;
    }
    final duration = deadline.difference(createdAt);
    return createdAt.add(Duration(
        milliseconds: (duration.inMilliseconds * 0.75).round()));
  }

  SlaStatus getSlaStatus(Task task, {required DateTime now}) {
    if (task.status == TaskStatus.completed) {
      return SlaStatus.completed;
    }

    final effectiveNow = task.status == TaskStatus.paused && task.pausedAt != null
        ? task.pausedAt!
        : now;

    if (effectiveNow.isAfter(task.deadline)) {
      return SlaStatus.overdue;
    } else if (effectiveNow.isAfter(task.atRiskAt) || effectiveNow.isAtSameMomentAs(task.atRiskAt)) {
      return SlaStatus.atRisk;
    } else {
      return SlaStatus.onTrack;
    }
  }

  // --- Mutations ---

  Future<Task> createTask({
    required String title,
    String description = '',
    String? assignedTo,
    required TaskPriority priority,
    required DateTime deadline,
  }) async {
    if (title.trim().isEmpty) {
      throw ValidationException('Task title cannot be empty.');
    }

    final now = _clock();
    if (deadline.isBefore(now)) {
      throw ValidationException('New task deadline cannot be in the past.');
    }

    final String id = _uuid.v4();
    final DateTime createdAt = now;
    final DateTime atRiskAt = computeAtRiskAt(createdAt, deadline);

    final task = Task(
      id: id,
      title: title.trim(),
      description: description.trim(),
      assignedTo: assignedTo?.trim().isEmpty == true ? null : assignedTo,
      priority: priority,
      deadline: deadline,
      status: TaskStatus.todo,
      createdAt: createdAt,
      updatedAt: createdAt,
      atRiskAt: atRiskAt,
    );

    await _db.insertTask(task);
    return task;
  }

  Future<Task> updateTaskFields(String id, {
    String? title,
    String? description,
    String? assignedTo,
    TaskPriority? priority,
    DateTime? deadline,
  }) async {
    final existingTask = await _db.getTaskById(id);
    if (existingTask == null) {
      throw NotFoundException('Task with ID $id not found.');
    }

    if (existingTask.status == TaskStatus.completed) {
      throw TaskServiceException('Cannot edit a completed task.');
    }

    if (title != null && title.trim().isEmpty) {
      throw ValidationException('Task title cannot be empty.');
    }

    if (existingTask.status == TaskStatus.paused && deadline != null && existingTask.deadline != deadline) {
      throw ValidationException('Cannot modify the deadline of a paused task.');
    }
    
    final now = _clock();
    if (deadline != null && deadline != existingTask.deadline && deadline.isBefore(now)) {
      throw ValidationException('New deadline cannot be in the past.');
    }

    final newAtRiskAt = deadline != null && deadline != existingTask.deadline
        ? computeAtRiskAt(existingTask.createdAt, deadline)
        : existingTask.atRiskAt;

    String? finalAssignee = existingTask.assignedTo;
    if (assignedTo != null) {
      finalAssignee = assignedTo.trim().isEmpty ? null : assignedTo;
    }

    final updatedTask = existingTask.copyWith(
      title: title?.trim() ?? existingTask.title,
      description: description?.trim() ?? existingTask.description,
      assignedTo: finalAssignee,
      priority: priority ?? existingTask.priority,
      deadline: deadline ?? existingTask.deadline,
      updatedAt: now,
      atRiskAt: newAtRiskAt,
    );

    await _db.updateTask(updatedTask);
    return updatedTask;
  }

  Future<Task> startTask(String id) async {
    final task = await _db.getTaskById(id);
    if (task == null) {
      throw NotFoundException('Task with ID $id not found.');
    }

    if (task.status != TaskStatus.todo) {
      throw TaskServiceException('Only Todo tasks can be started. Use resumeTask for Paused tasks.');
    }

    final updatedTask = task.copyWith(
      status: TaskStatus.inProgress,
      updatedAt: _clock(),
    );

    await _db.updateTask(updatedTask);
    return updatedTask;
  }

  Future<Task> pauseTask(String id) async {
    final task = await _db.getTaskById(id);
    if (task == null) {
      throw NotFoundException('Task with ID $id not found.');
    }

    if (task.status != TaskStatus.inProgress) {
      throw TaskServiceException('Only In Progress tasks can be paused.');
    }

    final now = _clock();
    final updatedTask = task.copyWith(
      status: TaskStatus.paused,
      pausedAt: now,
      updatedAt: now,
    );

    await _db.updateTask(updatedTask);
    return updatedTask;
  }

  Future<Task> resumeTask(String id) async {
    final task = await _db.getTaskById(id);
    if (task == null) {
      throw NotFoundException('Task with ID $id not found.');
    }

    if (task.status != TaskStatus.paused || task.pausedAt == null) {
      throw TaskServiceException('Only paused tasks can be resumed.');
    }

    final now = _clock();
    final pauseDuration = now.difference(task.pausedAt!);

    final newDeadline = task.deadline.add(pauseDuration);
    final newAtRiskAt = task.atRiskAt.add(pauseDuration);

    final updatedTask = task.copyWith(
      status: TaskStatus.inProgress,
      deadline: newDeadline,
      atRiskAt: newAtRiskAt,
      clearPausedAt: true,
      updatedAt: now,
    );

    await _db.updateTask(updatedTask);
    return updatedTask;
  }

  Future<Task> completeTask(String id) async {
    final task = await _db.getTaskById(id);
    if (task == null) {
      throw NotFoundException('Task with ID $id not found.');
    }

    if (task.status == TaskStatus.completed) {
      return task; // Already completed
    }

    final updatedTask = task.copyWith(
      status: TaskStatus.completed,
      clearPausedAt: true,
      updatedAt: _clock(),
    );

    await _db.updateTask(updatedTask);
    return updatedTask;
  }

  Future<void> deleteTask(String id) async {
    final task = await _db.getTaskById(id);
    if (task == null) {
      throw NotFoundException('Task with ID $id not found.');
    }
    await _db.deleteTask(id);
  }
}
