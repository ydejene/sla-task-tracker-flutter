import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_scope.dart';
import 'controllers/task_controller.dart';
import 'controllers/team_controller.dart';
import 'screens/auth/user_selection_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    AppScope(
      tasks: TaskController(),
      team: TeamController(),
      child: const SlatrixApp(),
    ),
  );
}

class SlatrixApp extends StatelessWidget {
  const SlatrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const UserSelectionScreen(),
    );
  }
}
