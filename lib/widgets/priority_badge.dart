import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';

/// Flag icon + priority label. Priority is independent from SLA status.
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority, this.compact = true});

  final Priority priority;
  final bool compact;

  static Color colorOf(Priority p) {
    switch (p) {
      case Priority.high:
        return AppColors.overdue;
      case Priority.medium:
        return AppColors.atRisk;
      case Priority.low:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = compact ? AppColors.meta : colorOf(priority);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flag_outlined, size: compact ? 15 : 17, color: iconColor),
        const SizedBox(width: 4),
        Text(
          priority.label,
          style: compact
              ? AppText.meta
              : const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
        ),
      ],
    );
  }
}
