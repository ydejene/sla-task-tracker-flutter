import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/exceptions.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/task_service.dart';
import '../utils/date_format.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_text_field.dart';
import '../widgets/screen_header.dart';
import '../widgets/task_colors.dart';

/// Create and Edit share this form. Pass a task to edit it, or nothing to
/// create a new one. Pops with true when a task was saved.
class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final Task? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final TaskService _service = TaskService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();

  List<TeamMember> _members = [];
  String? _assigneeId;
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _deadline;

  // Errors stay hidden until the first save attempt, then update live.
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  String? _loadError;
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isEditing => widget.task != null;
  bool get _isPaused => widget.task?.status == TaskStatus.paused;

  /// True when the user picked a deadline different from the saved one.
  bool get _deadlineChanged {
    final current = _deadline;
    if (current == null) return false;
    final original = widget.task?.deadline;
    return original == null || !current.isAtSameMomentAs(original);
  }

  bool get _hasChanges {
    final task = widget.task;
    if (task == null) return true;
    return _titleController.text.trim() != task.title ||
        _descriptionController.text.trim() != task.description ||
        _assigneeId != task.assignedTo ||
        _priority != task.priority ||
        _deadlineChanged;
  }

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _priority = task.priority;
      _deadline = task.deadline;
      _deadlineController.text = formatDeadline(task.deadline);
    }
    _loadMembers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loadError = null;
      _isLoading = true;
    });
    try {
      final members = await _service.getAllMembers();
      if (!mounted) return;
      final savedAssignee = widget.task?.assignedTo;
      setState(() {
        _members = members;
        _assigneeId = members.any((m) => m.id == savedAssignee) ? savedAssignee : null;
        _isLoading = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _isLoading = false;
      });
    }
  }

  // Validation. The messages for the three required fields come from the design.

  String? _validateTitle(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Enter a task title.';
    return null;
  }

  String? _validateAssignee(String? value) {
    return value == null ? 'Select an assignee.' : null;
  }

  /// A new task needs a future deadline. When editing, the deadline is only
  /// checked if it was changed, so an overdue task can still be edited.
  String? _validateDeadline(String? _) {
    final deadline = _deadline;
    if (deadline == null) return 'Add a deadline.';
    final mustBeFuture = !_isEditing || _deadlineChanged;
    if (mustBeFuture && !deadline.isAfter(DateTime.now())) {
      return 'Deadline cannot be in the past.';
    }
    return null;
  }

  // Actions

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Date and time pickers in the brand color.
  Widget _pickerTheme(BuildContext context, Widget? child) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(primary: TaskColors.primary),
      ),
      child: child!,
    );
  }

  Future<void> _pickDeadline() async {
    if (_isPaused) {
      _showMessage('The deadline is locked while the task is paused.');
      return;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = _deadline;
    final initialDate = (current != null && !current.isBefore(today)) ? current : today;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 5)),
      builder: _pickerTheme,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? now.add(const Duration(hours: 1))),
      builder: _pickerTheme,
    );
    if (time == null || !mounted) return;

    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      _deadline = picked;
      _deadlineController.text = formatDeadline(picked);
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _autovalidate = AutovalidateMode.always);
      return;
    }
    if (_isEditing && !_hasChanges) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _isSaving = true);
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    try {
      final task = widget.task;
      if (task == null) {
        await _service.createTask(
          title: title,
          description: description,
          assignedTo: _assigneeId,
          priority: _priority,
          deadline: _deadline!,
        );
      } else {
        await _service.updateTaskFields(
          task.id,
          title: title,
          description: description,
          assignedTo: _assigneeId,
          priority: _priority,
          // Pass null when untouched so an overdue task is not rejected.
          deadline: _deadlineChanged ? _deadline : null,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaskColors.pageBackground,
      body: Column(
        children: [
          ScreenHeader(
            title: _isEditing ? 'Edit Task' : 'Create Task',
            subtitle: _isEditing
                ? 'Update the task information'
                : 'Add the essentials to get started',
            onBack: () => Navigator.of(context).pop(false),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: TaskColors.primary, strokeWidth: 2.5),
      );
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: TaskColors.body),
              ),
              const SizedBox(height: 16),
              AppButton(label: 'Try again', onPressed: _loadMembers),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(21, 22, 21, 32),
        children: [
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Title',
                  controller: _titleController,
                  icon: Icons.fact_check_outlined,
                  hint: 'What needs to be done?',
                  isRequired: true,
                  maxLength: 80,
                  validator: _validateTitle,
                  autovalidateMode: _autovalidate,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'Description',
                  controller: _descriptionController,
                  icon: Icons.article_outlined,
                  hint: 'Add context or acceptance notes',
                  isOptional: true,
                  maxLines: 4,
                  maxLength: 500,
                ),
                const SizedBox(height: 18),
                AppDropdownField<String>(
                  label: 'Assignee',
                  icon: Icons.person_outline_rounded,
                  hint: 'Select a team member',
                  isRequired: true,
                  initialValue: _assigneeId,
                  items: [
                    for (final member in _members)
                      DropdownMenuItem(value: member.id, child: Text(member.name)),
                  ],
                  onChanged: (value) => setState(() => _assigneeId = value),
                  validator: _validateAssignee,
                  autovalidateMode: _autovalidate,
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: AppDropdownField<TaskPriority>(
                        label: 'Priority',
                        icon: Icons.flag_outlined,
                        initialValue: _priority,
                        items: [
                          for (final priority in TaskPriority.values)
                            DropdownMenuItem(value: priority, child: Text(priority.value)),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _priority = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      flex: 3,
                      child: AppTextField(
                        label: 'Deadline',
                        controller: _deadlineController,
                        icon: Icons.calendar_today_outlined,
                        hint: 'May 24, 4:00 PM',
                        isRequired: true,
                        readOnly: true,
                        onTap: _pickDeadline,
                        validator: _validateDeadline,
                        autovalidateMode: _autovalidate,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 84,
                height: 46,
                child: AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.secondary,
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: AppButton(
                    label: _isEditing ? 'Save Changes' : 'Create Task',
                    icon: Icons.check_rounded,
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
