import 'package:flutter/material.dart';

import 'task_colors.dart';

/// Lavender header with a back button, a title and an optional subtitle.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(bottom: Radius.circular(20));
    // Outer box is the 1px bottom border (a one-sided border cannot have
    // rounded corners in Flutter), inner box is the lavender fill.
    return Container(
      padding: const EdgeInsets.only(bottom: 1),
      decoration: const BoxDecoration(
        color: TaskColors.headerBorder,
        borderRadius: radius,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: TaskColors.headerBackground,
          borderRadius: radius,
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(21, 12, 21, 20),
            child: Row(
              children: [
                Material(
                  color: TaskColors.headerButtonBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: TaskColors.headerBorder),
                  ),
                  child: InkWell(
                    customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onTap: onBack,
                    child: const SizedBox(
                      width: 37,
                      height: 37,
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 24,
                        color: TaskColors.primaryDeep,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          height: 1.2,
                          color: TaskColors.heading,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: TaskColors.subtitle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
