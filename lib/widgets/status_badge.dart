import 'package:flutter/material.dart';

import '../models/enums.dart';
import 'task_colors.dart';

/// Neutral pill showing the workflow status (Todo, In Progress, Paused, Completed).
/// The label comes from TaskStatus.value.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: TaskColors.statusChipBackground,
        border: Border.all(color: TaskColors.statusChipBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.value,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: TaskColors.statusChipText,
        ),
      ),
    );
  }
}
