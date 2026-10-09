// Enums for the application

enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High');

  final String value;
  const TaskPriority(this.value);

  // Helper method to convert from DB string to Enum
  static TaskPriority fromString(String val) {
    return TaskPriority.values.firstWhere(
      (e) => e.value == val,
      orElse: () => TaskPriority.medium,
    );
  }
}

enum TaskStatus {
  todo('Todo'),
  inProgress('In Progress'),
  paused('Paused'),
  completed('Completed');

  final String value;
  const TaskStatus(this.value);

  // Helper method to convert from DB string to Enum
  static TaskStatus fromString(String val) {
    return TaskStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => TaskStatus.todo,
    );
  }
}

enum SlaStatus {
  onTrack('On Track'),
  atRisk('At Risk'),
  overdue('Overdue'),
  completed('Completed');

  final String value;
  const SlaStatus(this.value);

  // Note: slaStatus is not stored in DB, but value property is useful for UI
}
