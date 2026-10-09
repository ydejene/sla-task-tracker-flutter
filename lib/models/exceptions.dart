abstract class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

class ValidationException extends AppException {
  ValidationException(super.message);

  @override
  String toString() => 'Validation Error: $message';
}

class DatabaseException extends AppException {
  DatabaseException(super.message);

  @override
  String toString() => 'Database Error: $message';
}

class TaskServiceException extends AppException {
  TaskServiceException(super.message);

  @override
  String toString() => 'Task Service Error: $message';
}

class NotFoundException extends AppException {
  NotFoundException(super.message);

  @override
  String toString() => 'Not Found: $message';
}
