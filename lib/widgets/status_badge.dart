import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';

/// Visual tokens for each SLA status.
class SlaStyle {
  const SlaStyle({
    required this.color,
    required this.text,
    required this.soft,
    required this.tint,
    required this.tintBorder,
    required this.icon,
  });

  final Color color;
  final Color text;
  final Color soft;
  final Color tint;
  final Color tintBorder;
  final IconData icon;

  static SlaStyle of(SlaStatus status) {
    switch (status) {
      case SlaStatus.onTrack:
        return const SlaStyle(
          color: AppColors.onTrack,
          text: AppColors.onTrackText,
          soft: AppColors.onTrackSoft,
          tint: AppColors.onTrackTint,
          tintBorder: AppColors.onTrackTintBorder,
          icon: Icons.trending_up_rounded,
        );
      case SlaStatus.atRisk:
        return const SlaStyle(
          color: AppColors.atRisk,
          text: AppColors.atRiskText,
          soft: AppColors.atRiskSoft,
          tint: AppColors.atRiskTint,
          tintBorder: AppColors.atRiskTintBorder,
          icon: Icons.priority_high_rounded,
        );
      case SlaStatus.overdue:
        return const SlaStyle(
          color: AppColors.overdue,
          text: AppColors.overdueText,
          soft: AppColors.overdueSoft,
          tint: AppColors.overdueTint,
          tintBorder: AppColors.overdueTintBorder,
          icon: Icons.schedule_rounded,
        );
      case SlaStatus.completed:
        return const SlaStyle(
          color: AppColors.completed,
          text: AppColors.completedText,
          soft: AppColors.completedSoft,
          tint: AppColors.completedTint,
          tintBorder: AppColors.completedTintBorder,
          icon: Icons.check_rounded,
        );
    }
  }
}

/// Neutral pill showing the workflow status (Todo, In Progress, ...).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x17707080),
        border: Border.all(color: const Color(0x14707080)),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF686878),
        ),
      ),
    );
  }
}

/// Coloured dot + label showing the calculated SLA status.
class SlaBadge extends StatelessWidget {
  const SlaBadge({super.key, required this.status, this.large = false});

  final SlaStatus status;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final style = SlaStyle.of(status);
    final dot = large ? 25.0 : 21.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dot,
          height: dot,
          decoration: BoxDecoration(color: style.color, shape: BoxShape.circle),
          child: Icon(style.icon, size: dot * 0.6, color: Colors.white),
        ),
        const SizedBox(width: 6),
        Text(
          status.label,
          style: TextStyle(
            fontSize: large ? 13 : 11,
            fontWeight: FontWeight.w700,
            color: style.text,
          ),
        ),
      ],
    );
  }
}

/// Soft coloured pill (e.g. "Completed" in Recent Work).
class SoftPill extends StatelessWidget {
  const SoftPill({
    super.key,
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
