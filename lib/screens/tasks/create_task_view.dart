import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../models/task.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/common.dart';
import '../../widgets/member_avatar.dart';

/// Screen 5 — form used to create a task, or edit one when [task] is given.
class CreateTaskView extends StatefulWidget {
  const CreateTaskView({super.key, this.task});

  final Task? task;

  @override
  State<CreateTaskView> createState() => _CreateTaskViewState();
}

class _CreateTaskViewState extends State<CreateTaskView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  String? _assigneeId;
  late Priority _priority;
  late TaskStatus _status;
  DateTime? _deadline;
  String? _deadlineError;
  bool _saving = false;
  bool _initialised = false;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t?.title ?? '');
    _description = TextEditingController(text: t?.description ?? '');
    _assigneeId = t?.assignedTo;
    _priority = t?.priority ?? Priority.medium;
    _status = t?.status ?? TaskStatus.todo;
    _deadline = t?.deadline;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _initialised = true;
      // New tasks default to the current user.
      if (!_isEdit) _assigneeId = AppScope.of(context).team.currentUser?.id;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _isDirty {
    final t = widget.task;
    if (t == null) {
      return _title.text.isNotEmpty ||
          _description.text.isNotEmpty ||
          _deadline != null;
    }
    return _title.text != t.title ||
        _description.text != t.description ||
        _assigneeId != t.assignedTo ||
        _priority != t.priority ||
        _status != t.status ||
        _deadline != t.deadline;
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  String? _validateTitle(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Title is required';
    if (value.length < AppConstants.minTitleLength) {
      return 'Title must be at least ${AppConstants.minTitleLength} characters';
    }
    return null;
  }

  String? _validateDeadline() {
    final d = _deadline;
    if (d == null) return 'Choose a deadline';
    final unchanged = _isEdit && d == widget.task!.deadline;
    if (unchanged) return null;
    if (!d.isAfter(DateTime.now())) return 'Deadline must be in the future';
    if (_isEdit && !d.isAfter(widget.task!.createdAt)) {
      return 'Deadline must be after the task was created';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initial = _deadline ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 2)),
      helpText: 'Select deadline date',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _deadline ?? now.add(const Duration(hours: 1)),
      ),
      helpText: 'Select deadline time',
    );
    if (time == null) return;
    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _deadlineError = _validateDeadline();
    });
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    setState(() => _deadlineError = _validateDeadline());
    if (!formOk || _deadlineError != null) return;

    setState(() => _saving = true);
    final controller = AppScope.of(context).tasks;
    final Task saved;
    if (_isEdit) {
      saved = await controller.updateTask(
        widget.task!,
        title: _title.text,
        description: _description.text,
        assignedTo: _assigneeId!,
        priority: _priority,
        deadline: _deadline!,
        status: _status,
      );
    } else {
      saved = await controller.createTask(
        title: _title.text,
        description: _description.text,
        assignedTo: _assigneeId!,
        priority: _priority,
        deadline: _deadline!,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(saved);
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.overdue),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _cancel() async {
    if (await _confirmDiscard() && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final members = AppScope.of(context).team.members;

    return PopScope(
      // System back always goes through the discard check below.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            ScreenHeader(
              title: _isEdit ? 'Edit Task' : 'New Task',
              subtitle: _isEdit
                  ? 'Update the task information'
                  : 'Add a task for your team',
              onBack: _cancel,
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    22,
                    20,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    AppCard(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            label: 'Title',
                            icon: Icons.title_rounded,
                            controller: _title,
                            hint: 'What needs to be done?',
                            required: true,
                            maxLength: AppConstants.maxTitleLength,
                            textInputAction: TextInputAction.next,
                            validator: _validateTitle,
                          ),
                          const SizedBox(height: 18),
                          AppTextField(
                            label: 'Description',
                            icon: Icons.notes_rounded,
                            controller: _description,
                            hint: 'Add context or acceptance notes',
                            optional: true,
                            maxLines: 4,
                            maxLength: AppConstants.maxDescriptionLength,
                          ),
                          const SizedBox(height: 18),
                          AppDropdownField<String>(
                            label: 'Assignee',
                            icon: Icons.person_outline_rounded,
                            required: true,
                            value: members.any((m) => m.id == _assigneeId)
                                ? _assigneeId
                                : null,
                            hint: 'Choose a team member',
                            validator: (v) =>
                                v == null ? 'Choose an assignee' : null,
                            onChanged: (v) => setState(() => _assigneeId = v),
                            items: [
                              for (final m in members)
                                DropdownMenuItem(
                                  value: m.id,
                                  child: Row(
                                    children: [
                                      MemberAvatar(member: m, size: 24),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          m.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          AppDropdownField<Priority>(
                            label: 'Priority',
                            icon: Icons.flag_outlined,
                            value: _priority,
                            onChanged: (v) =>
                                setState(() => _priority = v ?? _priority),
                            items: [
                              for (final p in Priority.values)
                                DropdownMenuItem(
                                  value: p,
                                  child: Text(p.label),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          AppPickerField(
                            label: 'Deadline',
                            icon: Icons.event_outlined,
                            required: true,
                            text: _deadline == null
                                ? null
                                : Formatters.deadline(_deadline!),
                            hint: 'Pick a date and time',
                            errorText: _deadlineError,
                            onTap: _pickDeadline,
                          ),
                          if (_isEdit) ...[
                            const SizedBox(height: 18),
                            AppDropdownField<TaskStatus>(
                              label: 'Status',
                              icon: Icons.sync_alt_rounded,
                              value: _status,
                              onChanged: (v) =>
                                  setState(() => _status = v ?? _status),
                              items: [
                                for (final s in TaskStatus.values)
                                  DropdownMenuItem(
                                    value: s,
                                    child: Text(s.label),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'SLA status is calculated automatically. A task becomes '
                            'At Risk after 75% of the time between creation and deadline.',
                            style: AppText.caption,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        AppButton(
                          label: 'Cancel',
                          variant: AppButtonVariant.secondary,
                          onPressed: _saving ? null : _cancel,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton(
                            label: _isEdit ? 'Save Changes' : 'Create Task',
                            icon: _isEdit
                                ? Icons.check_rounded
                                : Icons.add_rounded,
                            loading: _saving,
                            onPressed: _save,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
