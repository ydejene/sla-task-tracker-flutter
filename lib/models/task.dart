enum Priority {
  low('Low'),
  medium('Medium'),
  high('High');

  const Priority(this.label);
  final String label;

  static Priority fromName(String name) =>
      Priority.values.firstWhere((p) => p.name == name, orElse: () => medium);
}

/// Workflow status of a task. This is set by the team.
enum TaskStatus {
  todo('Todo'),
  inProgress('In Progress'),
  paused('Paused'),
  completed('Completed');

  const TaskStatus(this.label);
  final String label;

  static TaskStatus fromName(String name) =>
      TaskStatus.values.firstWhere((s) => s.name == name, orElse: () => todo);
}

/// SLA health of a task. This is always calculated, never stored.
enum SlaStatus {
  onTrack('On Track'),
  atRisk('At Risk'),
  overdue('Overdue'),
  completed('Completed');

  const SlaStatus(this.label);
  final String label;
}

class Task {
  final String id;
  final String title;
  final String description;
  final String? assignedTo;
  final Priority priority;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime deadline;
  final DateTime atRiskAt;
  final DateTime? pausedAt;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.deadline,
    required this.atRiskAt,
    this.pausedAt,
  });

  bool get isCompleted => status == TaskStatus.completed;
  bool get isPaused => status == TaskStatus.paused;

  Task copyWith({
    String? title,
    String? description,
    String? assignedTo,
    bool clearAssignee = false,
    Priority? priority,
    TaskStatus? status,
    DateTime? updatedAt,
    DateTime? deadline,
    DateTime? atRiskAt,
    DateTime? pausedAt,
    bool clearPausedAt = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: clearAssignee ? null : (assignedTo ?? this.assignedTo),
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deadline: deadline ?? this.deadline,
      atRiskAt: atRiskAt ?? this.atRiskAt,
      pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
    );
  }

  /// Timestamps are stored as milliseconds since epoch (INTEGER columns).
  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'assigned_to': assignedTo,
    'priority': priority.name,
    'status': status.name,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
    'deadline': deadline.millisecondsSinceEpoch,
    'at_risk_at': atRiskAt.millisecondsSinceEpoch,
    'paused_at': pausedAt?.millisecondsSinceEpoch,
  };

  factory Task.fromMap(Map<String, Object?> map) {
    DateTime date(Object? v) => DateTime.fromMillisecondsSinceEpoch(v as int);
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      assignedTo: map['assigned_to'] as String?,
      priority: Priority.fromName(map['priority'] as String),
      status: TaskStatus.fromName(map['status'] as String),
      createdAt: date(map['created_at']),
      updatedAt: date(map['updated_at']),
      deadline: date(map['deadline']),
      atRiskAt: date(map['at_risk_at']),
      pausedAt: map['paused_at'] == null ? null : date(map['paused_at']),
    );
  }
}
