class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);

  @override
  String toString() => 'Validation Error: $message';
}

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => 'Database Error: $message';
}

class TaskServiceException implements Exception {
  final String message;
  TaskServiceException(this.message);

  @override
  String toString() => 'Task Service Error: $message';
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);

  @override
  String toString() => 'Not Found: $message';
}
