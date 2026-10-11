import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Colors for the task widgets and screens, taken from the Figma Make design.
/// Values that already exist in AppTheme point at it, so there is one source
/// of truth. The rest (SLA tints, label colors, card edge and shadow) are only
/// used by the task widgets, so they stay here.
class TaskColors {
  const TaskColors._();

  // Brand (shared with AppTheme)
  static const Color primary = AppTheme.primary;
  static const Color primaryDeep = AppTheme.primaryDeep;

  // Surfaces
  static const Color pageBackground = Color(0xFFF7F7FA); // phone shell background
  static const Color headerBackground = AppTheme.chrome;
  static const Color headerBorder = Color(0x1F6356D9); // primary @ 12%
  static const Color headerButtonBackground = Color(0xB3FFFFFF); // white @ 70%
  static const Color cardEdge = Color(0x0F202030); // rgba(32,32,48,.06)
  static const Color cardShadow = Color(0x0A1D1D2F); // rgba(29,29,47,.04)
  static const Color cardBorder = AppTheme.line; // dividers
  static const Color fieldBorder = Color(0xFFE4E3EC);
  static const Color buttonBorder = Color(0xFFDDDCE6);
  static const Color iconBackground = AppTheme.surfaceSoft;

  // Text
  static const Color heading = AppTheme.text;
  static const Color body = AppTheme.textSoft;
  static const Color muted = AppTheme.textFaint;
  static const Color subtitle = Color(0xFF5E5B78);
  static const Color cardDetail = Color(0xFF747483);

  // SLA solid colors (shared with AppTheme)
  static const Color onTrack = AppTheme.blue;
  static const Color atRisk = AppTheme.amber;
  static const Color overdue = AppTheme.red;
  static const Color completed = AppTheme.green;

  // SLA label text (darker than the solid color)
  static const Color onTrackText = Color(0xFF285BA9);
  static const Color atRiskText = Color(0xFFA5670E);
  static const Color overdueText = Color(0xFFB73A43);
  static const Color completedText = Color(0xFF22784F);

  // SLA tinted surface (color 6-7% over white) and its border (13-14%)
  static const Color onTrackSoft = Color(0xFFF4F7FD);
  static const Color onTrackBorder = Color(0xFFE6EDFA);
  static const Color atRiskSoft = Color(0xFFFCF7EF);
  static const Color atRiskBorder = Color(0xFFF9EFDF);
  static const Color overdueSoft = Color(0xFFFDF4F5);
  static const Color overdueBorder = Color(0xFFFAE8E9);
  static const Color completedSoft = Color(0xFFF2F9F6);
  static const Color completedBorder = Color(0xFFE4F2EB);

  // Neutral workflow status pill
  static const Color statusChipBackground = Color(0x17707080); // rgba(112,112,128,.09)
  static const Color statusChipBorder = Color(0x14707080); // .08
  static const Color statusChipText = Color(0xFF686878);
}
