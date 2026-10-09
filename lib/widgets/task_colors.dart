import 'package:flutter/material.dart';

/// Colors taken from the Figma for the Task Details and Task Form screens.
/// TEMPORARY: once the shared theme tokens exist, point these at the tokens
/// (or delete this file and use the theme directly).
class TaskColors {
  const TaskColors._();

  static const Color pageBackground = Color(0xFFF6F6FA);
  static const Color headerBackground = Color(0xFFEEEBFF);
  static const Color cardBorder = Color(0xFFEDEDF3);
  static const Color fieldBorder = Color(0xFFE4E3EC);
  static const Color buttonBorder = Color(0xFFE2E1EA);
  static const Color iconBackground = Color(0xFFF4F3FA);

  static const Color heading = Color(0xFF14142B);
  static const Color body = Color(0xFF6B6B7B);
  static const Color muted = Color(0xFF8A8A9A);

  static const Color onTrack = Color(0xFF3B7DD8);
  static const Color onTrackSoft = Color(0xFFEAF2FF);
  static const Color atRisk = Color(0xFFD48A12);
  static const Color atRiskSoft = Color(0xFFFFF4E0);
  static const Color overdue = Color(0xFFD64550);
  static const Color overdueSoft = Color(0xFFFFEDEE);
  static const Color completed = Color(0xFF2E9E6B);
  static const Color completedSoft = Color(0xFFE8F6EF);

  static const Color statusChipBackground = Color(0xFFEDE9EC);
  static const Color statusChipText = Color(0xFF6B6570);

  /// Accepts a hex string like '#DDF3E8' or a token like 'avatar_mint'
  /// (the seed data currently uses tokens such as avatar-mint).
  static Color avatarBackground(String value) {
    if (value.startsWith('#')) {
      final parsed = int.tryParse(value.substring(1), radix: 16);
      if (parsed != null) return Color(0xFF000000 | parsed);
    }
    if (value.contains('mint')) return const Color(0xFFDDF3E8);
    if (value.contains('blue')) return const Color(0xFFDCE8FF);
    if (value.contains('violet')) return const Color(0xFFE8E0FA);
    if (value.contains('sand')) return const Color(0xFFF2E6D6);
    return const Color(0xFFE0E0E8);
  }

  /// Darker version of a background, used for the initials.
  static Color avatarForeground(Color background) {
    return HSLColor.fromColor(background).withLightness(0.28).toColor();
  }
}
