import 'package:flutter/material.dart';
import '../../models/enums.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF6356D9);
  static const Color primaryDeep = Color(0xFF4F43BD);
  static const Color primarySoft = Color(0xFFEEECFF);
  
  static const Color background = Color(0xFFF4F5F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF8F8FB);
  
  static const Color chrome = Color(0xFFEFEDFF);
  static const Color chromeStrong = Color(0xFFDFDBFF);

  // Text Colors
  static const Color text = Color(0xFF171724);
  static const Color textSoft = Color(0xFF666778);
  static const Color textFaint = Color(0xFF9697A5);
  static const Color line = Color(0xFFE8E8EF);

  // Status Colors
  static const Color green = Color(0xFF2E9B68);
  static const Color greenSoft = Color(0xFFEAF7F0);
  
  static const Color amber = Color(0xFFD28A1D);
  static const Color amberSoft = Color(0xFFFFF5DF);
  
  static const Color red = Color(0xFFD94B54);
  static const Color redSoft = Color(0xFFFFF0F1);
  
  static const Color blue = Color(0xFF3F73D8);
  static const Color blueSoft = Color(0xFFEDF3FF);

  // Legacy Aliases for un-refactored screens
  static const Color primaryPurple = primary;
  static const Color primaryPurpleLight = primarySoft;
  static const Color textPrimary = text;
  static const Color textSecondary = textSoft;
  static const Color divider = line;
  static const Color slaOnTrack = blue;
  static const Color slaAtRisk = amber;
  static const Color slaOverdue = red;
  static const Color slaCompleted = green;
  static const Color priorityLow = blue;
  static const Color priorityMedium = amber;
  static const Color priorityHigh = red;

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: 'DM Sans',
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSoft,
        elevation: 8,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 23, letterSpacing: -0.035),
        titleLarge: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.02),
        titleMedium: TextStyle(color: text, fontWeight: FontWeight.w600, fontSize: 14),
        bodyLarge: TextStyle(color: text, fontSize: 12.5),
        bodyMedium: TextStyle(color: textSoft, fontSize: 11.5),
      ),
      useMaterial3: true,
    );
  }

  // Helpers to fetch appropriate colors quickly
  static Color getSlaColor(SlaStatus status) {
    switch (status) {
      case SlaStatus.onTrack: return blue;
      case SlaStatus.atRisk: return amber;
      case SlaStatus.overdue: return red;
      case SlaStatus.completed: return green;
    }
  }

  static Color getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low: return blue;
      case TaskPriority.medium: return amber;
      case TaskPriority.high: return red;
    }
  }
}

