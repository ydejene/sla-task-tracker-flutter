import 'package:flutter/material.dart';

import 'task_colors.dart';

/// One cell of the Task information grid: icon box, small label, and a value
/// widget underneath (plain text, an avatar with a name, an SLA badge, and so on).
class InfoTile extends StatelessWidget {
  const InfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 67),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: TaskColors.iconBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 17, color: TaskColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      color: TaskColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
