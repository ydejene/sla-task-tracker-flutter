import 'enums.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final String? assignedTo;
  final TaskPriority priority;
  final DateTime deadline;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime atRiskAt;
  final DateTime? pausedAt;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.assignedTo,
    required this.priority,
    required this.deadline,
    this.status = TaskStatus.todo,
    required this.createdAt,
    required this.updatedAt,
    required this.atRiskAt,
    this.pausedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assigned_to': assignedTo,
      'priority': priority.value,
      'deadline': deadline.toIso8601String(),
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'at_risk_at': atRiskAt.toIso8601String(),
      'paused_at': pausedAt?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      assignedTo: map['assigned_to'],
      priority: TaskPriority.fromString(map['priority']),
      deadline: DateTime.parse(map['deadline']),
      status: TaskStatus.fromString(map['status']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      atRiskAt: DateTime.parse(map['at_risk_at']),
      pausedAt: map['paused_at'] != null ? DateTime.parse(map['paused_at']) : null,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? assignedTo, 
    TaskPriority? priority,
    DateTime? deadline,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? atRiskAt,
    bool clearPausedAt = false,
    DateTime? pausedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      atRiskAt: atRiskAt ?? this.atRiskAt,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
    );
  }
}
