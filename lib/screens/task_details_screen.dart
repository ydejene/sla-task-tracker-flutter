import 'dart:async';

import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/exceptions.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/task_service.dart';
import '../utils/date_format.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/assignee_avatar.dart';
import '../widgets/info_tile.dart';
import '../widgets/screen_header.dart';
import '../widgets/sla_badge.dart';
import '../widgets/status_badge.dart';
import '../widgets/task_colors.dart';

/// Shows one task. Pops with true if anything changed (start, pause, resume,
/// complete, and later edit) so the previous screen can reload its list.
class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final TaskService _service = TaskService();

  Task? _task;
  TeamMember? _assignee;
  String? _loadError;
  bool _isLoading = true;
  bool _isBusy = false;
  bool _changed = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    // SLA status depends on the current time, so rebuild every minute.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loadError = null;
      if (_task == null) _isLoading = true;
    });
    try {
      final task = await _service.getTaskById(widget.taskId);
      if (task == null) throw NotFoundException('Task not found.');
      final assigneeId = task.assignedTo;
      final assignee =
          assigneeId == null ? null : await _service.getMemberById(assigneeId);
      if (!mounted) return;
      setState(() {
        _task = task;
        _assignee = assignee;
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

  /// Runs a status action. The service decides if it is allowed and throws an
  /// AppException with a message if not, which is shown in a SnackBar.
  Future<void> _runAction(Future<Task> Function() action) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final updated = await action();
      if (!mounted) return;
      setState(() {
        _task = updated;
        _changed = true;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _onEdit() {
    // Step two: open TaskFormScreen(task: _task) with Navigator.push<bool>.
    // When it returns true, set _changed = true and call _load().
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('The edit form comes in the next step.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // canPop is false so both the back button and the system back gesture end
    // up here, and we can return _changed to the previous screen.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: TaskColors.pageBackground,
        body: Column(
          children: [
            ScreenHeader(
              title: 'Task Details',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final task = _task;
    if (_loadError != null || task == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _loadError ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: TaskColors.body),
              ),
              const SizedBox(height: 16),
              AppButton(label: 'Try again', onPressed: _load),
            ],
          ),
        ),
      );
    }

    final sla = _service.getSlaStatus(task, now: DateTime.now());
    final primary = Theme.of(context).colorScheme.primary;
    final assignee = _assignee;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(
          'TASK',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          task.title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: TaskColors.heading,
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: SlaBadge.softColorFor(sla),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusBadge(status: task.status),
                const SizedBox(width: 8),
                SlaBadge(status: sla),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        const _SectionTitle('Description'),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.notes_rounded, size: 20, color: primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.description.trim().isEmpty
                      ? 'No description provided.'
                      : task.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: TaskColors.body,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const _SectionTitle('Task information'),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            children: [
              _InfoRow(
                left: InfoTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Assignee',
                  child: assignee == null
                      ? const _ValueText('Unassigned')
                      : Row(
                          children: [
                            AssigneeAvatar(member: assignee),
                            const SizedBox(width: 8),
                            Expanded(child: _ValueText(assignee.name)),
                          ],
                        ),
                ),
                right: InfoTile(
                  icon: Icons.flag_outlined,
                  label: 'Priority',
                  child: _ValueText(task.priority.value),
                ),
              ),
              const Divider(height: 1, color: TaskColors.cardBorder),
              _InfoRow(
                left: InfoTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Deadline',
                  child: _ValueText(formatDeadline(task.deadline)),
                ),
                right: InfoTile(
                  icon: Icons.checklist_rounded,
                  label: 'Task Status',
                  child: _ValueText(task.status.value),
                ),
              ),
              const Divider(height: 1, color: TaskColors.cardBorder),
              _InfoRow(
                left: InfoTile(
                  icon: Icons.timer_outlined,
                  label: 'SLA Status',
                  child: SlaBadge(status: sla, iconSize: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildActions(task),
      ],
    );
  }

  /// Buttons depend on the status:
  /// Todo: Edit, Start, Complete. In Progress: Edit, Pause, Complete.
  /// Paused: Edit, Resume, Complete. Completed: read only.
  Widget _buildActions(Task task) {
    if (task.status == TaskStatus.completed) {
      return const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text(
          'This task is completed and read only.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: TaskColors.muted),
        ),
      );
    }

    final middle = switch (task.status) {
      TaskStatus.todo => AppButton(
          label: 'Start',
          icon: Icons.play_arrow_rounded,
          variant: AppButtonVariant.secondary,
          onPressed: _isBusy ? null : () => _runAction(() => _service.startTask(task.id)),
        ),
      TaskStatus.inProgress => AppButton(
          label: 'Pause',
          icon: Icons.pause_rounded,
          variant: AppButtonVariant.secondary,
          onPressed: _isBusy ? null : () => _runAction(() => _service.pauseTask(task.id)),
        ),
      TaskStatus.paused => AppButton(
          label: 'Resume',
          icon: Icons.play_arrow_rounded,
          variant: AppButtonVariant.secondary,
          onPressed: _isBusy ? null : () => _runAction(() => _service.resumeTask(task.id)),
        ),
      TaskStatus.completed => const SizedBox.shrink(),
    };

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AppButton(
            label: 'Edit',
            icon: Icons.edit_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: _isBusy ? null : _onEdit,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: middle),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: AppButton(
            label: 'Complete',
            icon: Icons.check_rounded,
            onPressed: _isBusy ? null : () => _runAction(() => _service.completeTask(task.id)),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: TaskColors.heading,
      ),
    );
  }
}

/// Two column row with a vertical divider. A missing right tile stays empty.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.left, this.right});

  final Widget left;
  final Widget? right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const VerticalDivider(width: 1, color: TaskColors.cardBorder),
          Expanded(child: right ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}

class _ValueText extends StatelessWidget {
  const _ValueText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: TaskColors.heading,
      ),
    );
  }
}
