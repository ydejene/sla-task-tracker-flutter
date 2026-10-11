import 'package:flutter/material.dart';
import 'screens/user_selection_screen.dart';
import 'services/demo_data.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Add ensuring initialized since we have SQLite bindings underneath if needed
  WidgetsFlutterBinding.ensureInitialized();
  await seedDemoTasksIfEmpty();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SLA Task Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const UserSelectionScreen(),
    );
  }
}
