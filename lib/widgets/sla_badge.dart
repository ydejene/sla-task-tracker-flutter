import 'package:flutter/material.dart';

import '../models/enums.dart';
import 'task_colors.dart';

/// Round colored icon plus label for the four SLA states.
/// The static helpers let other widgets (like a task card) tint themselves
/// with the same colors.
class SlaBadge extends StatelessWidget {
  const SlaBadge({super.key, required this.status, this.iconSize = 28});

  final SlaStatus status;
  final double iconSize;

  static Color colorFor(SlaStatus status) => switch (status) {
        SlaStatus.onTrack => TaskColors.onTrack,
        SlaStatus.atRisk => TaskColors.atRisk,
        SlaStatus.overdue => TaskColors.overdue,
        SlaStatus.completed => TaskColors.completed,
      };

  static Color softColorFor(SlaStatus status) => switch (status) {
        SlaStatus.onTrack => TaskColors.onTrackSoft,
        SlaStatus.atRisk => TaskColors.atRiskSoft,
        SlaStatus.overdue => TaskColors.overdueSoft,
        SlaStatus.completed => TaskColors.completedSoft,
      };

  static IconData iconFor(SlaStatus status) => switch (status) {
        SlaStatus.onTrack => Icons.trending_up_rounded,
        SlaStatus.atRisk => Icons.schedule_rounded,
        SlaStatus.overdue => Icons.warning_amber_rounded,
        SlaStatus.completed => Icons.check_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(iconFor(status), size: iconSize * 0.57, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Text(
          status.value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
