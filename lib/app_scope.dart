import 'package:flutter/widgets.dart';

import 'controllers/task_controller.dart';
import 'controllers/team_controller.dart';

/// Makes the controllers reachable from any screen without a third-party
/// state-management package. It only provides access; screens still call
/// `setState()` after a controller action to rebuild.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.tasks,
    required this.team,
    required super.child,
  });

  final TaskController tasks;
  final TeamController team;

  static AppScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      tasks != oldWidget.tasks || team != oldWidget.team;
}
