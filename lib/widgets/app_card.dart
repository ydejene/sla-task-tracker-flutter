import 'package:flutter/material.dart';

import 'task_colors.dart';

/// White rounded container with a light border, used for grouped content.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TaskColors.cardBorder),
      ),
      child: child,
    );
  }
}
