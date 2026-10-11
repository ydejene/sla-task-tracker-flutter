import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/exceptions.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;
  final TeamMember currentUser;

  const TaskDetailsScreen({
    super.key,
    required this.taskId,
    required this.currentUser,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final TaskService _taskService = TaskService();
  final DatabaseService _dbService = DatabaseService();

  Task? _task;
  TeamMember? _assignee;
  bool _isLoading = true;
  bool _hasModified = false;

  @override
  void initState() {
    super.initState();
    _loadTaskDetails();
  }

  Future<void> _loadTaskDetails() async {
    try {
      final task = await _taskService.getTaskById(widget.taskId);
      TeamMember? assignee;
      if (task?.assignedTo != null) {
        assignee = await _dbService.getTeamMemberById(task!.assignedTo!);
      }

      if (mounted) {
        setState(() {
          _task = task;
          _assignee = assignee;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getSurfaceBg(SlaStatus sla) {
    switch (sla) {
      case SlaStatus.onTrack:
        return Color.alphaBlend(AppTheme.blue.withAlpha(15), AppTheme.surface);
      case SlaStatus.atRisk:
        return Color.alphaBlend(AppTheme.amber.withAlpha(18), AppTheme.surface);
      case SlaStatus.overdue:
        return Color.alphaBlend(AppTheme.red.withAlpha(15), AppTheme.surface);
      case SlaStatus.completed:
        return Color.alphaBlend(AppTheme.green.withAlpha(15), AppTheme.surface);
    }
  }

  Color _getBorderColor(SlaStatus sla) {
    switch (sla) {
      case SlaStatus.onTrack:
        return Color.alphaBlend(AppTheme.blue.withAlpha(33), AppTheme.surface);
      case SlaStatus.atRisk:
        return Color.alphaBlend(AppTheme.amber.withAlpha(36), AppTheme.surface);
      case SlaStatus.overdue:
        return Color.alphaBlend(AppTheme.red.withAlpha(33), AppTheme.surface);
      case SlaStatus.completed:
        return Color.alphaBlend(AppTheme.green.withAlpha(33), AppTheme.surface);
    }
  }

  IconData _getSlaIcon(SlaStatus sla) {
    switch (sla) {
      case SlaStatus.onTrack:
        return Icons.check;
      case SlaStatus.atRisk:
        return Icons.access_time_rounded;
      case SlaStatus.overdue:
        return Icons.priority_high_rounded;
      case SlaStatus.completed:
        return Icons.check_rounded;
    }
  }

  Future<void> _handleStart() async {
    try {
      await _taskService.startTask(widget.taskId);
      _hasModified = true;
      await _loadTaskDetails();
    } on AppException catch (e) {
      _showError(e.message);
    }
  }

  Future<void> _handlePause() async {
    try {
      await _taskService.pauseTask(widget.taskId);
      _hasModified = true;
      await _loadTaskDetails();
    } on AppException catch (e) {
      _showError(e.message);
    }
  }

  Future<void> _handleResume() async {
    try {
      await _taskService.resumeTask(widget.taskId);
      _hasModified = true;
      await _loadTaskDetails();
    } on AppException catch (e) {
      _showError(e.message);
    }
  }

  Future<void> _handleComplete() async {
    try {
      await _taskService.completeTask(widget.taskId);
      _hasModified = true;
      await _loadTaskDetails();
    } on AppException catch (e) {
      _showError(e.message);
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _taskService.deleteTask(widget.taskId);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } on AppException catch (e) {
        _showError(e.message);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_task == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Task Not Found')),
        body: const Center(child: Text('This task does not exist.')),
      );
    }

    final task = _task!;
    final slaStatus = _taskService.computeSlaStatus(task);
    final slaColor = AppTheme.getSlaColor(slaStatus);
    final isCompleted = task.status == TaskStatus.completed;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Return _hasModified to caller so parent screen refreshes
        if (!didPop) Navigator.pop(context, _hasModified);
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              onBack: () => Navigator.pop(context, _hasModified),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.textFaint),
                  onPressed: _handleDelete,
                  tooltip: 'Delete task',
                ),
              ],
              child: const Text(
                'Task Details',
                style: TextStyle(
                  color: AppTheme.text,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.035 * 23,
                  height: 1.2,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child:
              // Detail Content
              Padding(
                padding: const EdgeInsets.fromLTRB(21, 24, 21, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Detail Hero
                    const Text(
                      'TASK',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.08 * 10,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.03 * 22,
                        height: 1.25,
                        color: AppTheme.text,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Detail Status Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                          decoration: BoxDecoration(
                            color: _getSurfaceBg(slaStatus),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: _getBorderColor(slaStatus)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0x17707080),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: const Color(0x14707080)),
                                ),
                                child: Text(
                                  task.status.value,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF686878),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 25,
                                    height: 25,
                                    decoration: BoxDecoration(
                                      color: slaColor,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      _getSlaIcon(slaStatus),
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    slaStatus.value,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: slaColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Description Section
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(15),
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.description_outlined,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              task.description.isEmpty
                                  ? 'No description provided.'
                                  : task.description,
                              style: const TextStyle(
                                fontSize: 11.5,
                                height: 1.6,
                                color: AppTheme.textSoft,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Task Information Section
                    const Text(
                      'Task information',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
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
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailItem(
                                  icon: Icons.person_outline,
                                  label: 'Assignee',
                                  valueWidget: _assignee != null
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            AvatarWidget.fromMember(
                                              _assignee!,
                                              radius: 10,
                                              fontSize: 8.5,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                _assignee!.name,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.text,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Text(
                                          'Unassigned',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textSoft,
                                          ),
                                        ),
                                ),
                              ),
                              Container(width: 1, height: 67, color: AppTheme.line),
                              Expanded(
                                child: _buildDetailItem(
                                  icon: Icons.flag_outlined,
                                  label: 'Priority',
                                  valueWidget: Text(
                                    task.priority.value,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.text,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(height: 1, color: AppTheme.line),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailItem(
                                  icon: Icons.calendar_today_outlined,
                                  label: 'Deadline',
                                  valueWidget: Text(
                                    TaskCard.formatDeadline(task.deadline),
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.text,
                                    ),
                                  ),
                                ),
                              ),
                              Container(width: 1, height: 67, color: AppTheme.line),
                              Expanded(
                                child: _buildDetailItem(
                                  icon: Icons.checklist_rounded,
                                  label: 'Task Status',
                                  valueWidget: Text(
                                    task.status.value,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.text,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(height: 1, color: AppTheme.line),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDetailItem(
                                  icon: _getSlaIcon(slaStatus),
                                  label: 'SLA Status',
                                  valueWidget: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: slaColor,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          _getSlaIcon(slaStatus),
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        slaStatus.value,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: slaColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Actions Row
                    Row(
                      children: [
                        // Edit button (disabled if completed)
                        if (!isCompleted)
                          InkWell(
                            onTap: () async {
                              final updated = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TaskFormScreen(
                                    task: task,
                                    currentUser: widget.currentUser,
                                  ),
                                ),
                              );
                              if (updated == true) {
                                _hasModified = true;
                                _loadTaskDetails();
                              }
                            },
                            borderRadius: BorderRadius.circular(11),
                            child: Container(
                              height: 42,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(color: const Color(0xFFDDDCE6)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_outlined, size: 17, color: AppTheme.textSoft),
                                  SizedBox(width: 6),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (!isCompleted) const SizedBox(width: 9),

                        // Lifecycle Action: Start / Pause / Resume
                        if (task.status == TaskStatus.todo)
                          Expanded(
                            child: InkWell(
                              onTap: _handleStart,
                              borderRadius: BorderRadius.circular(11),
                              child: Container(
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(color: const Color(0xFFDDDCE6)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_arrow_rounded, size: 18, color: AppTheme.textSoft),
                                    SizedBox(width: 6),
                                    Text(
                                      'Start',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else if (task.status == TaskStatus.inProgress)
                          Expanded(
                            child: InkWell(
                              onTap: _handlePause,
                              borderRadius: BorderRadius.circular(11),
                              child: Container(
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(color: const Color(0xFFDDDCE6)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.pause_rounded, size: 18, color: AppTheme.textSoft),
                                    SizedBox(width: 6),
                                    Text(
                                      'Pause',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else if (task.status == TaskStatus.paused)
                          Expanded(
                            child: InkWell(
                              onTap: _handleResume,
                              borderRadius: BorderRadius.circular(11),
                              child: Container(
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(color: const Color(0xFFDDDCE6)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_arrow_rounded, size: 18, color: AppTheme.textSoft),
                                    SizedBox(width: 6),
                                    Text(
                                      'Resume',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        if (!isCompleted) const SizedBox(width: 9),

                        // Complete Button (Primary)
                        if (!isCompleted)
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: _handleComplete,
                              borderRadius: BorderRadius.circular(11),
                              child: Container(
                                height: 42,
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
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_rounded, size: 18, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text(
                                      'Complete',
                                      style: TextStyle(
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required Widget valueWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minHeight: 67),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.surfaceSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 17, color: AppTheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppTheme.textFaint,
                  ),
                ),
                const SizedBox(height: 3),
                valueWidget,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
