import 'package:flutter/material.dart';

import '../models/enums.dart';
import 'task_colors.dart';

/// Solid round icon plus label for the four SLA states.
/// Default size is 25 (detail screen); use compact: true (20) for task cards
/// and info tiles. The static helpers let other widgets (like a task card)
/// tint themselves with the same colors.
class SlaBadge extends StatelessWidget {
  const SlaBadge({
    super.key,
    required this.status,
    this.compact = false,
    this.iconSize,
  });

  final SlaStatus status;
  final bool compact;

  /// Optional override for the circle size. 20 or smaller counts as compact.
  final double? iconSize;

  static Color colorFor(SlaStatus status) => switch (status) {
    SlaStatus.onTrack => TaskColors.onTrack,
    SlaStatus.atRisk => TaskColors.atRisk,
    SlaStatus.overdue => TaskColors.overdue,
    SlaStatus.completed => TaskColors.completed,
  };

  static Color textColorFor(SlaStatus status) => switch (status) {
    SlaStatus.onTrack => TaskColors.onTrackText,
    SlaStatus.atRisk => TaskColors.atRiskText,
    SlaStatus.overdue => TaskColors.overdueText,
    SlaStatus.completed => TaskColors.completedText,
  };

  /// Tinted card/row background for the status.
  static Color softColorFor(SlaStatus status) => switch (status) {
    SlaStatus.onTrack => TaskColors.onTrackSoft,
    SlaStatus.atRisk => TaskColors.atRiskSoft,
    SlaStatus.overdue => TaskColors.overdueSoft,
    SlaStatus.completed => TaskColors.completedSoft,
  };

  /// Border that goes with softColorFor.
  static Color borderColorFor(SlaStatus status) => switch (status) {
    SlaStatus.onTrack => TaskColors.onTrackBorder,
    SlaStatus.atRisk => TaskColors.atRiskBorder,
    SlaStatus.overdue => TaskColors.overdueBorder,
    SlaStatus.completed => TaskColors.completedBorder,
  };

  static IconData iconFor(SlaStatus status) => switch (status) {
    SlaStatus.onTrack => Icons.check_circle_outline_rounded,
    SlaStatus.atRisk => Icons.schedule_rounded,
    SlaStatus.overdue => Icons.warning_amber_rounded,
    SlaStatus.completed => Icons.check_box_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final isCompact = compact || (iconSize != null && iconSize! <= 20);
    final size = iconSize ?? (isCompact ? 20.0 : 25.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colorFor(status),
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconFor(status),
            size: isCompact ? 11 : 14,
            color: Colors.white,
          ),
        ),
        SizedBox(width: isCompact ? 5 : 6),
        Text(
          status.value,
          style: TextStyle(
            fontSize: isCompact ? 9.5 : 11,
            fontWeight: FontWeight.w700,
            color: textColorFor(status),
          ),
        ),
      ],
    );
  }
}
