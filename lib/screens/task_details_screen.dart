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
import 'task_form_screen.dart';

/// Shows one task. Pops with true if anything changed (start, pause, resume,
/// complete or edit) so the previous screen can reload its list.
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _onEdit() async {
    final task = _task;
    if (task == null) return;
    if (task.status == TaskStatus.completed) {
      _showMessage('Completed tasks cannot be edited.');
      return;
    }
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
    );
    if (saved == true && mounted) {
      _changed = true;
      await _load();
    }
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
      return const Center(
        child: CircularProgressIndicator(color: TaskColors.primary, strokeWidth: 2.5),
      );
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
                style: const TextStyle(fontSize: 12, color: TaskColors.body),
              ),
              const SizedBox(height: 16),
              AppButton(label: 'Try again', onPressed: _load),
            ],
          ),
        ),
      );
    }

    final sla = _service.getSlaStatus(task, now: DateTime.now());
    final assignee = _assignee;

    return ListView(
      padding: const EdgeInsets.fromLTRB(21, 0, 21, 32),
      children: [
        // Hero: overline, title and the status and SLA row (.detail-hero).
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 24, 2, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TASK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: TaskColors.primary,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.66,
                  height: 1.25,
                  color: TaskColors.heading,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: SlaBadge.softColorFor(sla),
                  border: Border.all(color: SlaBadge.borderColorFor(sla)),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusBadge(status: task.status),
                    const SizedBox(width: 10),
                    SlaBadge(status: sla),
                  ],
                ),
              ),
            ],
          ),
        ),
        _Section(
          title: 'Description',
          child: AppCard(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.article_outlined, size: 18, color: TaskColors.primary),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    task.description.trim().isEmpty
                        ? 'No description provided.'
                        : task.description,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.6,
                      color: TaskColors.body,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _Section(
          title: 'Task information',
          child: AppCard(
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
                              const SizedBox(width: 6),
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
                const _RowDivider(),
                _InfoRow(
                  left: InfoTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Deadline',
                    child: _ValueText(formatDeadline(task.deadline)),
                  ),
                  right: InfoTile(
                    icon: Icons.fact_check_outlined,
                    label: 'Task Status',
                    child: _ValueText(task.status.value),
                  ),
                ),
                const _RowDivider(),
                _InfoRow(
                  left: InfoTile(
                    icon: SlaBadge.iconFor(sla),
                    label: 'SLA Status',
                    child: SlaBadge(status: sla, compact: true),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildActions(task),
      ],
    );
  }

  /// Edit is always shown, like the design. The status action depends on the
  /// status (Start, Pause or Resume) and Complete is shown until completed.
  Widget _buildActions(Task task) {
    final Widget? statusAction = switch (task.status) {
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
          icon: Icons.refresh_rounded,
          variant: AppButtonVariant.secondary,
          onPressed: _isBusy ? null : () => _runAction(() => _service.resumeTask(task.id)),
        ),
      TaskStatus.completed => null,
    };

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          AppButton(
            label: 'Edit',
            icon: Icons.edit_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: _isBusy ? null : _onEdit,
          ),
          if (statusAction != null) ...[
            const SizedBox(width: 9),
            statusAction,
          ],
          if (task.status != TaskStatus.completed) ...[
            const SizedBox(width: 9),
            Expanded(
              child: AppButton(
                label: 'Complete',
                icon: Icons.check_rounded,
                onPressed: _isBusy
                    ? null
                    : () => _runAction(() => _service.completeTask(task.id)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A titled block with 24px above it (.detail-section).
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: TaskColors.heading,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Two column row with a vertical divider. A missing right tile stays empty,
/// as in the design.
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
          const VerticalDivider(width: 1, thickness: 1, color: TaskColors.cardBorder),
          Expanded(child: right ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: TaskColors.cardBorder);
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
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: TaskColors.heading,
      ),
    );
  }
}
