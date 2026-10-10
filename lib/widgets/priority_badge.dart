import 'package:flutter/material.dart';

import '../models/enums.dart';
import 'task_colors.dart';

/// Flag icon with the priority label (Low, Medium, High).
/// Priority is independent from SLA status, so it uses neutral colors.
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.flag_outlined, size: 14, color: TaskColors.cardDetail),
        const SizedBox(width: 4),
        Text(
          priority.value,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: TaskColors.cardDetail,
          ),
        ),
      ],
    );
  }
}
