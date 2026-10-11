import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/exceptions.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_card.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  final TeamMember currentUser;

  const TaskFormScreen({
    super.key,
    this.task,
    required this.currentUser,
  });

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final TaskService _taskService = TaskService();
  final DatabaseService _dbService = DatabaseService();

  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  String? _selectedAssigneeId;
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _selectedDeadline;

  List<TeamMember> _teamMembers = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(text: widget.task?.description ?? '');
    _selectedAssigneeId = widget.task?.assignedTo ?? widget.currentUser.id;
    _selectedPriority = widget.task?.priority ?? TaskPriority.medium;
    _selectedDeadline = widget.task?.deadline ?? DateTime.now().add(const Duration(hours: 4));
    _loadTeamMembers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamMembers() async {
    try {
      final members = await _dbService.getAllTeamMembers();
      if (mounted) {
        setState(() {
          _teamMembers = members;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDeadline() async {
    final initialDate = _selectedDeadline ?? DateTime.now().add(const Duration(hours: 4));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: widget.task != null ? widget.task!.createdAt : DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null || !mounted) return;

    final initialTime = TimeOfDay.fromDateTime(initialDate);
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDeadline = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _save() async {
    setState(() => _submitted = true);

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Please enter a task title.');
      return;
    }

    if (_selectedDeadline == null) {
      _showError('Please select a deadline.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.task == null) {
        // Create Task
        await _taskService.createTask(
          title: title,
          description: _descController.text.trim(),
          assignedTo: _selectedAssigneeId,
          priority: _selectedPriority,
          deadline: _selectedDeadline!,
        );
      } else {
        // Update Task
        await _taskService.updateTaskFields(
          widget.task!.id,
          title: title,
          description: _descController.text.trim(),
          assignedTo: _selectedAssigneeId,
          priority: _selectedPriority,
          deadline: _selectedDeadline!,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on AppException catch (e) {
      setState(() => _isSaving = false);
      _showError(e.message);
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Failed to save task: ${e.toString()}');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final hasTitleError = _submitted && _titleController.text.trim().isEmpty;
    final hasDeadlineError = _submitted && _selectedDeadline == null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Workflow Header matching prototype
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.chrome,
                border: Border(
                  bottom: BorderSide(color: Color(0x1F6356D9), width: 1),
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(21, 52, 21, 20),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context, false),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 37,
                      height: 37,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(180),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x1F6356D9)),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: AppTheme.primaryDeep,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Task' : 'Create Task',
                          style: const TextStyle(
                            color: AppTheme.text,
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.035 * 23,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isEditing
                              ? 'Update the task information'
                              : 'Add the essentials to get started',
                          style: const TextStyle(
                            color: Color(0xFF5E5B78),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form Card
            Padding(
              padding: const EdgeInsets.fromLTRB(21, 22, 21, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0x0F202030)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A1D1D2F),
                          blurRadius: 22,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Field
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4F4F5E),
                            ),
                            children: [
                              TextSpan(text: 'Title '),
                              TextSpan(
                                text: '*',
                                style: TextStyle(color: AppTheme.red),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          constraints: const BoxConstraints(minHeight: 43),
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          decoration: BoxDecoration(
                            color: hasTitleError
                                ? Color.alphaBlend(AppTheme.red.withAlpha(10), AppTheme.surface)
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: hasTitleError
                                  ? AppTheme.red.withAlpha(140)
                                  : AppTheme.line,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.checklist_rounded, size: 17, color: Color(0xFF8D8C9A)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _titleController,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.text),
                                  decoration: const InputDecoration(
                                    hintText: 'What needs to be done?',
                                    hintStyle: TextStyle(color: Color(0xFFAAAAB6), fontSize: 11),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 11),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasTitleError) ...[
                          const SizedBox(height: 5),
                          const Text(
                            'Enter a task title.',
                            style: TextStyle(color: AppTheme.red, fontSize: 9),
                          ),
                        ],

                        const SizedBox(height: 18),

                        // Description Field
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4F4F5E),
                              ),
                            ),
                            Text(
                              'Optional',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontStyle: FontStyle.italic,
                                color: AppTheme.textFaint,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.line),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.description_outlined, size: 17, color: Color(0xFF8D8C9A)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _descController,
                                  maxLines: 4,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.text, height: 1.5),
                                  decoration: const InputDecoration(
                                    hintText: 'Add context or acceptance notes',
                                    hintStyle: TextStyle(color: Color(0xFFAAAAB6), fontSize: 11),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Assignee Field
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4F4F5E),
                            ),
                            children: [
                              TextSpan(text: 'Assignee '),
                              TextSpan(
                                text: '*',
                                style: TextStyle(color: AppTheme.red),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          constraints: const BoxConstraints(minHeight: 43),
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.line),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline, size: 17, color: Color(0xFF8D8C9A)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedAssigneeId,
                                    isExpanded: true,
                                    hint: const Text('Select a team member', style: TextStyle(fontSize: 11, color: Color(0xFFAAAAB6))),
                                    items: _teamMembers.map((member) {
                                      return DropdownMenuItem<String>(
                                        value: member.id,
                                        child: Text(
                                          '${member.name} (${member.role})',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.text),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedAssigneeId = val;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Row: Priority & Deadline
                        Row(
                          children: [
                            // Priority
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Priority',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4F4F5E),
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Container(
                                    constraints: const BoxConstraints(minHeight: 43),
                                    padding: const EdgeInsets.symmetric(horizontal: 11),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppTheme.line),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.flag_outlined, size: 17, color: Color(0xFF8D8C9A)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<TaskPriority>(
                                              value: _selectedPriority,
                                              isExpanded: true,
                                              items: TaskPriority.values.map((p) {
                                                return DropdownMenuItem<TaskPriority>(
                                                  value: p,
                                                  child: Text(
                                                    p.value,
                                                    style: const TextStyle(fontSize: 11, color: AppTheme.text),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setState(() => _selectedPriority = val);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 11),

                            // Deadline
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF4F4F5E),
                                      ),
                                      children: [
                                        TextSpan(text: 'Deadline '),
                                        TextSpan(
                                          text: '*',
                                          style: TextStyle(color: AppTheme.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  InkWell(
                                    onTap: _pickDeadline,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      constraints: const BoxConstraints(minHeight: 43),
                                      padding: const EdgeInsets.symmetric(horizontal: 11),
                                      decoration: BoxDecoration(
                                        color: hasDeadlineError
                                            ? Color.alphaBlend(AppTheme.red.withAlpha(10), AppTheme.surface)
                                            : AppTheme.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: hasDeadlineError
                                              ? AppTheme.red.withAlpha(140)
                                              : AppTheme.line,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF8D8C9A)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _selectedDeadline != null
                                                  ? TaskCard.formatDeadline(_selectedDeadline!)
                                                  : 'Set deadline',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: _selectedDeadline != null
                                                    ? AppTheme.text
                                                    : const Color(0xFFAAAAB6),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions Row: Cancel & Submit
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context, false),
                        borderRadius: BorderRadius.circular(11),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: const Color(0xFFDDDCE6)),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSoft,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: InkWell(
                          onTap: _isSaving ? null : _save,
                          borderRadius: BorderRadius.circular(11),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x386356D9),
                                  blurRadius: 12,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        isEditing ? 'Save Changes' : 'Create Task',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
