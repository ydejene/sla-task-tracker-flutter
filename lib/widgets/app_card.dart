import 'package:flutter/material.dart';

import 'task_colors.dart';

/// White rounded container with a hairline border and soft shadow,
/// used for grouped content (description card, task information card).
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: TaskColors.cardEdge),
        boxShadow: const [
          BoxShadow(
            color: TaskColors.cardShadow,
            blurRadius: 22,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
