import 'package:flutter/material.dart';

import '../models/enums.dart';
import 'task_colors.dart';

/// Grey pill showing the workflow status (Todo, In Progress, Paused, Completed).
/// The label comes from TaskStatus.value.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: TaskColors.statusChipBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.value,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: TaskColors.statusChipText,
        ),
      ),
    );
  }
}
