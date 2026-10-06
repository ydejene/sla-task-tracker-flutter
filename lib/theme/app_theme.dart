import 'package:flutter/material.dart';

/// Design tokens taken from the SLAtrix Figma design system.
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF6356D9);
  static const primaryDark = Color(0xFF4F43BD);
  static const primarySoft = Color(0xFFEEECFF);
  static const headerBg = Color(0xFFEFEDFF);
  static const navBg = Color(0xFFF4F1FF);
  static const navActive = Color(0xFFDFDBFF);
  static const navInactive = Color(0xFF7F7A99);

  // Surfaces
  static const background = Color(0xFFF7F7FA);
  static const surface = Colors.white;
  static const surfaceMuted = Color(0xFFF8F8FB);
  static const border = Color(0xFFE8E8EF);
  static const borderStrong = Color(0xFFDDDCE6);
  static const cardBorder = Color(0x0F202030);

  // Text
  static const ink = Color(0xFF171724);
  static const textSecondary = Color(0xFF666778);
  static const textMuted = Color(0xFF9697A5);
  static const textSubtle = Color(0xFF5E5B78);
  static const label = Color(0xFF4F4F5E);
  static const meta = Color(0xFF747483);
  static const chevron = Color(0xFFAAA8B6);

  // SLA – On Track
  static const onTrack = Color(0xFF3F73D8);
  static const onTrackText = Color(0xFF285BA9);
  static const onTrackSoft = Color(0xFFEDF3FF);
  static const onTrackTint = Color(0xFFF3F7FD);
  static const onTrackTintBorder = Color(0xFFE6EDFA);

  // SLA – At Risk
  static const atRisk = Color(0xFFD28A1D);
  static const atRiskText = Color(0xFFA5670E);
  static const atRiskSoft = Color(0xFFFFF5DF);
  static const atRiskTint = Color(0xFFFCF7EF);
  static const atRiskTintBorder = Color(0xFFF9EFDF);

  // SLA – Overdue
  static const overdue = Color(0xFFD94B54);
  static const overdueText = Color(0xFFB73A43);
  static const overdueSoft = Color(0xFFFFF0F1);
  static const overdueTint = Color(0xFFFDF4F5);
  static const overdueTintBorder = Color(0xFFFAE8E9);

  // SLA – Completed
  static const completed = Color(0xFF2E9B68);
  static const completedText = Color(0xFF22784F);
  static const completedSoft = Color(0xFFEAF7F0);
  static const completedTint = Color(0xFFF2F9F6);
  static const completedTintBorder = Color(0xFFE4F2EB);
}

class AppRadius {
  AppRadius._();
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 15.0;
  static const xl = 22.0;
  static const pill = 999.0;
}

class AppShadows {
  AppShadows._();
  static const card = [
    BoxShadow(color: Color(0x0B1D1D2F), blurRadius: 22, offset: Offset(0, 6)),
  ];
  static const primary = [
    BoxShadow(color: Color(0x386356D9), blurRadius: 16, offset: Offset(0, 6)),
  ];
  static const avatar = [
    BoxShadow(color: Color(0x242A2458), blurRadius: 12, offset: Offset(0, 3)),
  ];
}

class AppTheme {
  AppTheme._();

  static const fontFamily = 'DM Sans';

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      splashFactory: InkSparkle.splashFactory,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: Colors.white,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: Colors.white,
      ),
      timePickerTheme: const TimePickerThemeData(backgroundColor: Colors.white),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        showDragHandle: true,
      ),
    );
  }
}

/// Text styles used across screens, mirroring the Figma type scale.
class AppText {
  AppText._();

  static const eyebrow = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.primary,
  );
  static const display = TextStyle(
    fontSize: 27,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.ink,
  );
  static const screenTitle = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
  static const screenSubtitle = TextStyle(
    fontSize: 14,
    color: AppColors.textSubtle,
  );
  static const sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
  static const sectionSubtitle = TextStyle(
    fontSize: 12.5,
    color: AppColors.textMuted,
  );
  static const cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
  static const body = TextStyle(
    fontSize: 13,
    height: 1.45,
    color: AppColors.textSecondary,
  );
  static const caption = TextStyle(fontSize: 11.5, color: AppColors.textMuted);
  static const meta = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.meta,
  );
  static const button = TextStyle(fontSize: 13, fontWeight: FontWeight.w700);
}
