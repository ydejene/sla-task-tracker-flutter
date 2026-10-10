import 'package:flutter/material.dart';

import 'task_colors.dart';

enum AppButtonVariant { primary, secondary }

/// Shared button: filled purple for the main action, white outlined for the
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
    final isPrimary = variant == AppButtonVariant.primary;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(11),
    );
    const textStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w700);
    const padding = EdgeInsets.symmetric(horizontal: 14);
    const minimumSize = Size(0, 42);
    final handler = isLoading ? null : onPressed;

    final Widget content = isLoading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isPrimary ? Colors.white : TaskColors.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: isPrimary ? 18 : 17),
                const SizedBox(width: 6),
              ],
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          );

    if (isPrimary) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          boxShadow: handler == null
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x386356D9), // primary @ 22%
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
        ),
        child: FilledButton(
          onPressed: handler,
          style: FilledButton.styleFrom(
            backgroundColor: TaskColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: TaskColors.primary.withAlpha(140),
            disabledForegroundColor: Colors.white,
            shape: shape,
            textStyle: textStyle,
            padding: padding,
            minimumSize: minimumSize,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            elevation: 0,
          ),
          child: content,
        ),
      );
    }

    return OutlinedButton(
      onPressed: handler,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: TaskColors.body,
        disabledForegroundColor: TaskColors.body.withAlpha(120),
        side: const BorderSide(color: TaskColors.buttonBorder),
        shape: shape,
        textStyle: textStyle,
        padding: padding,
        minimumSize: minimumSize,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: content,
    );
  }
}
