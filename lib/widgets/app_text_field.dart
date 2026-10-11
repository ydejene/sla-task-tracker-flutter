import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'task_colors.dart';

// Form field colors from the design (.form-field and .input-shell in index.css).
const Color _labelColor = Color(0xFF4F4F5E);
const Color _hintColor = Color(0xFFAAAAB6);
const Color _fieldIconColor = Color(0xFF8D8C9A);
const Color _invalidBackground = Color(0xFFFDF8F8); // red 4% over white
const Color _invalidBorder = Color(0x8CD94B54); // red 55%
const Color _focusBorder = Color(0x806356D9); // primary 50%
const Color _focusRing = Color(0x146356D9); // primary 8%

const TextStyle _inputStyle = TextStyle(
  fontSize: 11,
  color: TaskColors.heading,
);

/// Label above a field, a red star when required, or a small "Optional" tag
/// on the right.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    required this.isRequired,
    required this.isOptional,
  });

  final String label;
  final bool isRequired;
  final bool isOptional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              children: [
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: TaskColors.overdue),
                  ),
              ],
            ),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: _labelColor,
            ),
          ),
          const Spacer(),
          if (isOptional)
            const Padding(
              padding: EdgeInsets.only(right: 2),
              child: Text(
                'Optional',
                style: TextStyle(fontSize: 8.5, color: TaskColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}

/// Label, input shell and error message stacked like the design's .form-field.
class _FieldFrame extends StatelessWidget {
  const _FieldFrame({
    required this.label,
    required this.isRequired,
    required this.isOptional,
    required this.errorText,
    required this.shell,
  });

  final String label;
  final bool isRequired;
  final bool isOptional;
  final String? errorText;
  final Widget shell;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, isRequired: isRequired, isOptional: isOptional),
        shell,
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              errorText!,
              style: const TextStyle(fontSize: 9, color: TaskColors.overdue),
            ),
          ),
      ],
    );
  }
}

/// The white rounded box around every input (.input-shell): icon on the left,
/// the input on the right, a purple ring while focused and a red tint when
/// invalid.
class _InputShell extends StatelessWidget {
  const _InputShell({
    required this.focusNode,
    required this.icon,
    required this.hasError,
    required this.child,
    this.alignTop = false,
  });

  final FocusNode focusNode;
  final IconData icon;
  final bool hasError;
  final Widget child;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        final borderColor = hasError
            ? _invalidBorder
            : focused
                ? _focusBorder
                : TaskColors.cardBorder;
        return Container(
          constraints: const BoxConstraints(minHeight: 43),
          padding: EdgeInsets.fromLTRB(11, alignTop ? 12 : 0, 11, 0),
          decoration: BoxDecoration(
            color: hasError ? _invalidBackground : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
            boxShadow: focused
                ? const [BoxShadow(color: _focusRing, spreadRadius: 3)]
                : null,
          ),
          child: Row(
            crossAxisAlignment:
                alignTop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: _fieldIconColor),
              const SizedBox(width: 8),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

/// Labelled text input with validation. Pass readOnly and onTap for a field
/// that opens a picker (like the deadline) instead of the keyboard.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.isRequired = false,
    this.isOptional = false,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.onTap,
    this.textInputAction,
    this.autovalidateMode,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final bool isRequired;
  final bool isOptional;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputAction? textInputAction;
  final AutovalidateMode? autovalidateMode;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMultiline = widget.maxLines > 1;

    return FormField<String>(
      initialValue: widget.controller.text,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      builder: (state) {
        Widget input = TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          readOnly: widget.readOnly,
          showCursor: !widget.readOnly,
          enableInteractiveSelection: !widget.readOnly,
          minLines: isMultiline ? widget.maxLines : 1,
          maxLines: widget.maxLines,
          inputFormatters: [
            if (widget.maxLength != null)
              LengthLimitingTextInputFormatter(widget.maxLength),
          ],
          textInputAction: widget.textInputAction,
          textCapitalization: widget.readOnly
              ? TextCapitalization.none
              : TextCapitalization.sentences,
          cursorColor: TaskColors.primary,
          onChanged: state.didChange,
          style: _inputStyle.copyWith(height: isMultiline ? 1.5 : null),
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            hintText: widget.hint,
            hintStyle: _inputStyle.copyWith(
              color: _hintColor,
              height: isMultiline ? 1.5 : null,
            ),
          ),
        );

        if (widget.readOnly) {
          // Any tap on the box opens the picker, not the keyboard.
          input = IgnorePointer(child: input);
        }

        Widget shell = _InputShell(
          focusNode: _focusNode,
          icon: widget.icon,
          hasError: state.hasError,
          alignTop: isMultiline,
          child: input,
        );

        if (widget.readOnly) {
          shell = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: shell,
          );
        }

        return _FieldFrame(
          label: widget.label,
          isRequired: widget.isRequired,
          isOptional: widget.isOptional,
          errorText: state.errorText,
          shell: shell,
        );
      },
    );
  }
}

/// Labelled dropdown with the same look as AppTextField (assignee, priority).
/// Like the design's select, it shows no arrow.
class AppDropdownField<T> extends StatefulWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.initialValue,
    this.hint,
    this.isRequired = false,
    this.validator,
    this.autovalidateMode,
  });

  final String label;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final T? initialValue;
  final String? hint;
  final bool isRequired;
  final String? Function(T?)? validator;
  final AutovalidateMode? autovalidateMode;

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: widget.initialValue,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      builder: (state) {
        return _FieldFrame(
          label: widget.label,
          isRequired: widget.isRequired,
          isOptional: false,
          errorText: state.errorText,
          shell: _InputShell(
            focusNode: _focusNode,
            icon: widget.icon,
            hasError: state.hasError,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: state.value,
                focusNode: _focusNode,
                isExpanded: true,
                icon: const SizedBox.shrink(),
                hint: widget.hint == null
                    ? null
                    : Text(widget.hint!, style: _inputStyle),
                style: _inputStyle,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(10),
                items: widget.items,
                onChanged: (value) {
                  state.didChange(value);
                  widget.onChanged(value);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
