import 'package:flutter/material.dart';

import 'task_colors.dart';

enum AppButtonVariant { primary, secondary }

/// Shared button: filled for the main action, white outlined for the
/// secondary ones. A null onPressed disables it, and isLoading shows a spinner.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    const textStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);
    const padding = EdgeInsets.symmetric(horizontal: 12);
    final handler = isLoading ? null : onPressed;

    final Widget content = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 6),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    return SizedBox(
      height: 52,
      child: variant == AppButtonVariant.primary
          ? FilledButton(
              onPressed: handler,
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                shape: shape,
                textStyle: textStyle,
                padding: padding,
                elevation: 0,
              ),
              child: content,
            )
          : OutlinedButton(
              onPressed: handler,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: TaskColors.heading,
                side: const BorderSide(color: TaskColors.buttonBorder),
                shape: shape,
                textStyle: textStyle,
                padding: padding,
              ),
              child: content,
            ),
    );
  }
}
