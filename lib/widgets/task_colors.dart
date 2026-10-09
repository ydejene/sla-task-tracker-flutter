import 'package:flutter/material.dart';

/// Colors taken from the Figma Make design (index.css tokens).
/// TEMPORARY: once the shared theme tokens exist, point these at the tokens
/// (or delete this file and use the theme directly).
class TaskColors {
  const TaskColors._();

  // Brand
  static const Color primary = Color(0xFF6356D9);
  static const Color primaryDeep = Color(0xFF4F43BD);

  // Surfaces
  static const Color pageBackground = Color(0xFFF7F7FA);
  static const Color headerBackground = Color(0xFFEFEDFF);
  static const Color headerBorder = Color(0x1F6356D9); // primary @ 12%
  static const Color headerButtonBackground = Color(0xB3FFFFFF); // white @ 70%
  static const Color cardEdge = Color(0x0F202030); // rgba(32,32,48,.06)
  static const Color cardShadow = Color(0x0A1D1D2F); // rgba(29,29,47,.04)
  static const Color cardBorder = Color(
    0xFFE8E8EF,
  ); // --line, used for dividers
  static const Color fieldBorder = Color(0xFFE4E3EC);
  static const Color buttonBorder = Color(0xFFDDDCE6);
  static const Color iconBackground = Color(0xFFF8F8FB); // --surface-soft

  // Text
  static const Color heading = Color(0xFF171724);
  static const Color body = Color(0xFF666778); // --text-soft
  static const Color muted = Color(0xFF9697A5); // --text-faint
  static const Color subtitle = Color(0xFF5E5B78);
  static const Color cardDetail = Color(0xFF747483);

  // SLA solid colors
  static const Color onTrack = Color(0xFF3F73D8);
  static const Color atRisk = Color(0xFFD28A1D);
  static const Color overdue = Color(0xFFD94B54);
  static const Color completed = Color(0xFF2E9B68);

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
  static const Color statusChipBackground = Color(
    0x17707080,
  ); // rgba(112,112,128,.09)
  static const Color statusChipBorder = Color(0x14707080); // .08
  static const Color statusChipText = Color(0xFF686878);

  /// Accepts a hex string like '#DDF3E8' or a token like 'avatar_mint'
  /// (the seed data currently uses tokens such as avatar-mint).
  static Color avatarBackground(String value) {
    if (value.startsWith('#')) {
      final parsed = int.tryParse(value.substring(1), radix: 16);
      if (parsed != null) return Color(0xFF000000 | parsed);
    }
    if (value.contains('mint')) return const Color(0xFFDFF2E9);
    if (value.contains('blue')) return const Color(0xFFE2EBFB);
    if (value.contains('violet')) return const Color(0xFFEBE4FB);
    if (value.contains('sand')) return const Color(0xFFF3EADB);
    return const Color(0xFFE0E0E8);
  }

  /// Initials color paired with each avatar background in the design.
  /// Unknown backgrounds (custom hex) fall back to a darkened version.
  static Color avatarForeground(Color background) {
    if (background == const Color(0xFFDFF2E9)) return const Color(0xFF267A54);
    if (background == const Color(0xFFE2EBFB)) return const Color(0xFF3D609B);
    if (background == const Color(0xFFEBE4FB)) return const Color(0xFF694A9D);
    if (background == const Color(0xFFF3EADB)) return const Color(0xFF8B6532);
    return HSLColor.fromColor(background).withLightness(0.28).toColor();
  }
}
