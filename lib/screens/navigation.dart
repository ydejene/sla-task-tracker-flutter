import 'package:flutter/material.dart';

import '../models/task.dart';
import 'auth/user_selection_screen.dart';
import 'tasks/create_task_view.dart';
import 'tasks/task_detail_view.dart';
import 'team/profile_screen.dart';

/// Central place for route pushes so every screen navigates the same way.
class AppNavigation {
  AppNavigation._();

  static Route<T> _route<T>(Widget page) =>
      MaterialPageRoute<T>(builder: (_) => page);

  static Future<void> openTask(BuildContext context, String taskId) =>
      Navigator.of(context).push(_route(TaskDetailView(taskId: taskId)));

  /// Returns the created task, or null if the user cancelled.
  static Future<Task?> createTask(BuildContext context) =>
      Navigator.of(context).push<Task>(_route(const CreateTaskView()));

  /// Returns the saved task, or null if the user cancelled.
  static Future<Task?> editTask(BuildContext context, Task task) =>
      Navigator.of(context).push<Task>(_route(CreateTaskView(task: task)));

  static Future<void> openMember(BuildContext context, String memberId) =>
      Navigator.of(context)
          .push(_route(MemberProfileScreen(memberId: memberId)));

  static void switchUser(BuildContext context) {
    Navigator.of(context)
        .pushAndRemoveUntil(_route(const UserSelectionScreen()), (_) => false);
  }
}
