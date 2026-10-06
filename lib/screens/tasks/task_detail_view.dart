import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../models/task.dart';
import '../../models/team_member.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/status_badge.dart';
import '../navigation.dart';

/// Screen 4 — complete information about one task, plus status actions.
class TaskDetailView extends StatefulWidget {
  const TaskDetailView({super.key, required this.taskId});

  final String taskId;

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  bool _busy = false;

  Future<void> _setStatus(Task task, TaskStatus status, String message) async {
    setState(() => _busy = true);
    await AppScope.of(context).tasks.updateTaskStatus(task, status);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit(Task task) async {
    final saved = await AppNavigation.editTask(context, task);
    if (!mounted) return;
    setState(() {});
    if (saved != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Changes saved')));
    }
  }

  Future<void> _delete(Task task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"${task.title}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.overdue),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await AppScope.of(context).tasks.deleteTask(task.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text('Deleted "${task.title}"')));
  }

  Future<void> _pickStatus(Task task) async {
    final picked = await showModalBottomSheet<TaskStatus>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Update status', style: AppText.sectionTitle),
              ),
              RadioGroup<TaskStatus>(
                groupValue: task.status,
                onChanged: (v) => Navigator.pop(context, v),
                child: Column(
                  children: [
                    for (final s in TaskStatus.values)
                      RadioListTile<TaskStatus>(
                        value: s,
                        title: Text(s.label),
                        activeColor: AppColors.primary,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && picked != task.status && mounted) {
      await _setStatus(task, picked, 'Status changed to ${picked.label}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final task = scope.tasks.getTask(widget.taskId);

    if (task == null) {
      return Scaffold(
        body: Column(
          children: [
            ScreenHeader(
              title: 'Task Details',
              onBack: () => Navigator.of(context).pop(),
            ),
            const Expanded(
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Task not found',
                message: 'This task may have been deleted.',
              ),
            ),
          ],
        ),
      );
    }

    final sla = scope.tasks.slaOf(task);
    final style = SlaStyle.of(sla);
    final assignee = scope.team.getMember(task.assignedTo);

    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(
            title: 'Task Details',
            onBack: () => Navigator.of(context).pop(),
            trailing: HeaderIconButton(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Delete task',
              color: AppColors.overdue,
              onTap: () => _delete(task),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                22,
                20,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                const Text('TASK', style: AppText.eyebrow),
                const SizedBox(height: 6),
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: style.tint,
                      border: Border.all(color: style.tintBorder),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge(status: task.status),
                        const SizedBox(width: 9),
                        SlaBadge(status: sla, large: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Description', style: _sectionStyle),
                const SizedBox(height: 10),
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.notes_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          task.description.isEmpty
                              ? 'No description provided.'
                              : task.description,
                          style: AppText.body,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text('Task information', style: _sectionStyle),
                const SizedBox(height: 10),
                _InfoGrid(
                  task: task,
                  sla: sla,
                  assignee: assignee,
                  onStatusTap: () => _pickStatus(task),
                ),
                const SizedBox(height: 22),
                const Text('SLA timeline', style: _sectionStyle),
                const SizedBox(height: 10),
                _SlaTimeline(task: task, sla: sla),
                const SizedBox(height: 24),
                _Actions(
                  task: task,
                  busy: _busy,
                  onEdit: () => _edit(task),
                  onStatus: (s, msg) => _setStatus(task, s, msg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _sectionStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w700,
  color: AppColors.ink,
);

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({
    required this.task,
    required this.sla,
    required this.assignee,
    required this.onStatusTap,
  });

  final Task task;
  final SlaStatus sla;
  final TeamMember? assignee;
  final VoidCallback onStatusTap;

  @override
  Widget build(BuildContext context) {
    const valueStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    );
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 6),
      child: Column(
        children: [
          Row(
            children: [
              _InfoTile(
                icon: Icons.person_outline_rounded,
                label: 'Assignee',
                value: Row(
                  children: [
                    MemberAvatar(member: assignee, size: 26),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        assignee?.name ?? 'Unassigned',
                        overflow: TextOverflow.ellipsis,
                        style: valueStyle,
                      ),
                    ),
                  ],
                ),
              ),
              _InfoTile(
                icon: Icons.flag_outlined,
                label: 'Priority',
                value: PriorityBadge(priority: task.priority, compact: false),
              ),
            ],
          ),
          Row(
            children: [
              _InfoTile(
                icon: Icons.event_outlined,
                label: 'Deadline',
                value: Text(
                  Formatters.deadline(task.deadline),
                  style: valueStyle,
                ),
              ),
              _InfoTile(
                icon: Icons.sync_alt_rounded,
                label: 'Task Status',
                onTap: onStatusTap,
                value: Row(
                  children: [
                    Text(task.status.label, style: valueStyle),
                    const Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              _InfoTile(
                icon: Icons.shield_outlined,
                label: 'SLA Status',
                value: SlaBadge(status: sla),
              ),
              _InfoTile(
                icon: Icons.history_rounded,
                label: 'Created',
                value: Text(
                  Formatters.deadline(task.createdAt),
                  style: valueStyle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14, right: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(
                icon: icon,
                color: AppColors.primary,
                background: AppColors.surfaceMuted,
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppText.caption.copyWith(fontSize: 11)),
                    const SizedBox(height: 4),
                    value,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows how far through its lifecycle the task is, with the 75% At Risk
/// threshold marked, so the SLA rules are visible to the user.
class _SlaTimeline extends StatelessWidget {
  const _SlaTimeline({required this.task, required this.sla});

  final Task task;
  final SlaStatus sla;

  @override
  Widget build(BuildContext context) {
    final service = AppScope.of(context).tasks.sla;
    final style = SlaStyle.of(sla);
    final progress = service.lifecycleProgress(task);
    final now = DateTime.now();

    final String headline;
    switch (sla) {
      case SlaStatus.completed:
        headline = 'Completed — SLA met';
      case SlaStatus.overdue:
        headline =
            'Overdue by ${Formatters.duration(now.difference(task.deadline))}';
      case SlaStatus.atRisk:
        headline =
            '${Formatters.duration(task.deadline.difference(task.pausedAt ?? now))} left before deadline';
      case SlaStatus.onTrack:
        headline =
            'At Risk in ${Formatters.duration(task.atRiskAt.difference(now))}';
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(style.icon, size: 18, color: style.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  headline,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: style.text,
                  ),
                ),
              ),
            ],
          ),
          if (task.isPaused) ...[
            const SizedBox(height: 6),
            Text(
              'Paused ${Formatters.timeAgo(task.pausedAt!)} — the SLA clock is frozen. '
              'Resuming shifts the deadline by the paused time.',
              style: AppText.caption.copyWith(fontSize: 11.5),
            ),
          ],
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return SizedBox(
                height: 14,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEFF4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Container(
                      height: 8,
                      width: w * (sla == SlaStatus.completed ? 1 : progress),
                      decoration: BoxDecoration(
                        color: style.color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Positioned(
                      left: w * AppConstants.atRiskThreshold - 1,
                      child: Container(
                        width: 2,
                        height: 14,
                        color: AppColors.atRisk,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TimelineLabel(
                  'Created',
                  Formatters.deadline(task.createdAt),
                ),
              ),
              Expanded(
                child: _TimelineLabel(
                  'At Risk (75%)',
                  Formatters.deadline(task.atRiskAt),
                  align: CrossAxisAlignment.center,
                ),
              ),
              Expanded(
                child: _TimelineLabel(
                  'Deadline',
                  Formatters.deadline(task.deadline),
                  align: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineLabel extends StatelessWidget {
  const _TimelineLabel(
    this.label,
    this.value, {
    this.align = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final textAlign = switch (align) {
      CrossAxisAlignment.center => TextAlign.center,
      CrossAxisAlignment.end => TextAlign.end,
      _ => TextAlign.start,
    };
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          textAlign: textAlign,
          style: AppText.caption.copyWith(fontSize: 10.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: textAlign,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.label,
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.task,
    required this.busy,
    required this.onEdit,
    required this.onStatus,
  });

  final Task task;
  final bool busy;
  final VoidCallback onEdit;
  final void Function(TaskStatus status, String message) onStatus;

  @override
  Widget build(BuildContext context) {
    final (IconData, String, TaskStatus, String) secondary =
        switch (task.status) {
          TaskStatus.todo => (
            Icons.play_arrow_rounded,
            'Start',
            TaskStatus.inProgress,
            'Task started',
          ),
          TaskStatus.inProgress => (
            Icons.pause_rounded,
            'Pause',
            TaskStatus.paused,
            'Task paused — SLA clock frozen',
          ),
          TaskStatus.paused => (
            Icons.play_arrow_rounded,
            'Resume',
            TaskStatus.inProgress,
            'Task resumed — deadline shifted',
          ),
          TaskStatus.completed => (
            Icons.replay_rounded,
            'Reopen',
            TaskStatus.inProgress,
            'Task reopened',
          ),
        };

    return Row(
      children: [
        AppButton(
          label: 'Edit',
          icon: Icons.edit_outlined,
          variant: AppButtonVariant.secondary,
          onPressed: busy ? null : onEdit,
        ),
        const SizedBox(width: 9),
        AppButton(
          label: secondary.$2,
          icon: secondary.$1,
          variant: AppButtonVariant.secondary,
          onPressed: busy ? null : () => onStatus(secondary.$3, secondary.$4),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: AppButton(
            label: task.isCompleted ? 'Completed' : 'Complete',
            icon: Icons.check_circle_outline_rounded,
            loading: busy,
            onPressed: task.isCompleted
                ? null
                : () => onStatus(TaskStatus.completed, 'Task completed'),
          ),
        ),
      ],
    );
  }
}
