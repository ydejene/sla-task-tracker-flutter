import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

InputDecoration _decoration({required IconData icon, String? hint}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    prefixIcon: Icon(icon, size: 19, color: const Color(0xFF8D8C9A)),
    prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 20),
    enabledBorder: border(AppColors.border),
    border: border(AppColors.border),
    focusedBorder: border(AppColors.primary, 1.4),
    errorBorder: border(AppColors.overdue),
    focusedErrorBorder: border(AppColors.overdue, 1.4),
    errorStyle: const TextStyle(fontSize: 11.5, color: AppColors.overdue),
    errorMaxLines: 2,
  );
}

const _inputStyle = TextStyle(fontSize: 13.5, color: AppColors.ink);

/// Label row: "Title *" or "Description … Optional".
class FieldLabel extends StatelessWidget {
  const FieldLabel(
    this.label, {
    super.key,
    this.required = false,
    this.optional = false,
  });

  final String label;
  final bool required;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.label,
            ),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: AppColors.overdue,
              ),
            ),
          const Spacer(),
          if (optional)
            const Text(
              'Optional',
              style: TextStyle(
                fontSize: 10.5,
                fontStyle: FontStyle.italic,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.hint,
    this.validator,
    this.required = false,
    this.optional = false,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final bool required;
  final bool optional;
  final int maxLines;
  final int? maxLength;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, required: required, optional: optional),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          minLines: maxLines > 1 ? 3 : 1,
          maxLength: maxLength,
          textInputAction: textInputAction,
          textCapitalization: TextCapitalization.sentences,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: _inputStyle,
          decoration: _decoration(
            icon: icon,
            hint: hint,
          ).copyWith(counterText: '', alignLabelWithHint: true),
        ),
      ],
    );
  }
}

class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.validator,
    this.required = false,
  });

  final String label;
  final IconData icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final FormFieldValidator<T>? validator;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, required: required),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          isExpanded: true,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: _inputStyle,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(
            Icons.expand_more_rounded,
            color: AppColors.textMuted,
          ),
          decoration: _decoration(icon: icon, hint: hint),
        ),
      ],
    );
  }
}

/// Read-only field that opens a picker on tap (used for the deadline).
class AppPickerField extends StatelessWidget {
  const AppPickerField({
    super.key,
    required this.label,
    required this.icon,
    required this.text,
    required this.onTap,
    this.hint,
    this.errorText,
    this.required = false,
  });

  final String label;
  final IconData icon;
  final String? text;
  final VoidCallback onTap;
  final String? hint;
  final String? errorText;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, required: required),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            isEmpty: text == null,
            decoration: _decoration(icon: icon, hint: hint).copyWith(
              errorText: errorText,
              suffixIcon: const Icon(
                Icons.edit_calendar_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
            child: Text(text ?? '', style: _inputStyle),
          ),
        ),
      ],
    );
  }
}
