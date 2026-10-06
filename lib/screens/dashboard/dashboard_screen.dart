import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../controllers/task_controller.dart';
import '../../models/task.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/task_card.dart';
import '../navigation.dart';

/// Screen 2 — high-level overview and main navigation hub.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onOpenTasks,
    required this.onOpenProfile,
    required this.onChanged,
  });

  final ValueChanged<TaskFilter> onOpenTasks;
  final VoidCallback onOpenProfile;

  /// Notifies the shell that data changed so sibling tabs rebuild.
  final VoidCallback onChanged;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void> _openTask(Task task) async {
    await AppNavigation.openTask(context, task.id);
    if (!mounted) return;
    setState(() {});
    widget.onChanged();
  }

  Future<void> _refresh() async {
    await AppScope.of(context).tasks.refreshTasks();
    if (!mounted) return;
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final tasks = scope.tasks;
    final user = scope.team.currentUser;
    final now = DateTime.now();
    final attention = tasks.needsAttention;
    final recent = tasks.recent(AppConstants.recentWorkLimit);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ScreenHeader(
            eyebrow: Formatters.headerDate(now),
            title: '${Formatters.greeting(now)}, ${user?.firstName ?? 'there'}',
            subtitle: 'Here’s where your team stands today.',
            trailing: GestureDetector(
              onTap: widget.onOpenProfile,
              child: MemberAvatar(
                member: user,
                size: 50,
                ring: true,
                online: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'SLA Health',
                  subtitle:
                      '${Formatters.plural(tasks.tasks.length - tasks.countByStatus(TaskStatus.completed), 'active task')} · ${tasks.tasks.length} tracked',
                ),
                _HealthCard(
                  controller: tasks,
                  onOpenFilter: widget.onOpenTasks,
                ),
                const SizedBox(height: 26),
                SectionHeader(
                  title: 'Needs Attention',
                  subtitle: 'Prioritized by urgency',
                  trailing: Row(
                    children: [
                      CountPill(
                        label: Formatters.plural(attention.length, 'task'),
                        color: AppColors.overdue,
                        background: AppColors.overdueSoft,
                      ),
                      const SizedBox(width: 8),
                      _SmallIconButton(
                        icon: Icons.tune_rounded,
                        tooltip: 'Open task list',
                        onTap: () => widget.onOpenTasks(TaskFilter.all),
                      ),
                    ],
                  ),
                ),
                if (attention.isEmpty)
                  const AppCard(
                    child: Row(
                      children: [
                        IconTile(
                          icon: Icons.celebration_outlined,
                          color: AppColors.completed,
                          background: AppColors.completedSoft,
                          size: 38,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'All caught up — no tasks are at risk or overdue.',
                            style: AppText.body,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final t in attention.take(3))
                    TaskCard(
                      task: t,
                      sla: tasks.slaOf(t),
                      assignee: scope.team.getMember(t.assignedTo),
                      onTap: () => _openTask(t),
                    ),
                if (attention.length > 3)
                  Center(
                    child: TextButton(
                      onPressed: () => widget.onOpenTasks(TaskFilter.overdue),
                      child: Text('View all ${attention.length} tasks'),
                    ),
                  ),
                const SizedBox(height: 22),
                const SectionHeader(title: 'Recent Work'),
                if (recent.isEmpty)
                  const AppCard(
                    child: Text('No activity yet.', style: AppText.body),
                  )
                else
                  for (final t in recent)
                    _RecentItem(
                      task: t,
                      sla: tasks.slaOf(t),
                      who: scope.team.getMember(t.assignedTo)?.firstName,
                      onTap: () => _openTask(t),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.controller, required this.onOpenFilter});

  final TaskController controller;
  final ValueChanged<TaskFilter> onOpenFilter;

  @override
  Widget build(BuildContext context) {
    final counts = controller.slaCounts;
    final ratio = controller.healthRatio;
    final attention = counts[SlaStatus.atRisk]! + counts[SlaStatus.overdue]!;

    final String headline;
    if (controller.tasks.isEmpty) {
      headline = 'No tasks yet';
    } else if (attention == 0) {
      headline = 'Everything is on track';
    } else if (ratio >= 0.7) {
      headline = 'Your team is in good shape';
    } else if (ratio >= 0.4) {
      headline = 'Some work needs a push';
    } else {
      headline = 'Delivery is at risk';
    }
    final message = attention == 0
        ? 'No tasks need attention right now.'
        : '${Formatters.plural(attention, 'task')} need${attention == 1 ? 's' : ''} attention to keep this week on track.';

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: CustomPaint(
                    painter: _DonutPainter(counts),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(ratio * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const Text(
                            'healthy',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          IconTile(
                            icon: Icons.monitor_heart_outlined,
                            color: AppColors.primary,
                            background: AppColors.primarySoft,
                            size: 22,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Overall task health',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        headline,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: AppText.body.copyWith(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          IntrinsicHeight(
            child: Row(
              children: [
                _StatCell(
                  status: SlaStatus.onTrack,
                  count: counts[SlaStatus.onTrack]!,
                  onTap: () => onOpenFilter(TaskFilter.all),
                ),
                const VerticalDivider(width: 1, color: AppColors.border),
                _StatCell(
                  status: SlaStatus.atRisk,
                  count: counts[SlaStatus.atRisk]!,
                  onTap: () => onOpenFilter(TaskFilter.atRisk),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          IntrinsicHeight(
            child: Row(
              children: [
                _StatCell(
                  status: SlaStatus.overdue,
                  count: counts[SlaStatus.overdue]!,
                  onTap: () => onOpenFilter(TaskFilter.overdue),
                ),
                const VerticalDivider(width: 1, color: AppColors.border),
                _StatCell(
                  status: SlaStatus.completed,
                  count: counts[SlaStatus.completed]!,
                  onTap: () => onOpenFilter(TaskFilter.completed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.status,
    required this.count,
    required this.onTap,
  });

  final SlaStatus status;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = SlaStyle.of(status);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              IconTile(
                icon: style.icon,
                color: style.color,
                background: style.soft,
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status.label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.counts);

  final Map<SlaStatus, int> counts;

  static const _order = [
    SlaStatus.completed,
    SlaStatus.onTrack,
    SlaStatus.atRisk,
    SlaStatus.overdue,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0xFFEFEFF4);
    canvas.drawArc(rect, 0, math.pi * 2, false, base);

    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;

    const gap = 0.06;
    var start = -math.pi / 2;
    final nonZero = _order.where((s) => counts[s]! > 0).length;
    for (final s in _order) {
      final n = counts[s]!;
      if (n == 0) continue;
      final sweep = math.pi * 2 * n / total;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = SlaStyle.of(s).color;
      final g = nonZero > 1 ? gap + 0.08 : 0.0;
      canvas.drawArc(
        rect,
        start + g / 2,
        math.max(sweep - g, 0.01),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => true;
}

class _RecentItem extends StatelessWidget {
  const _RecentItem({
    required this.task,
    required this.sla,
    required this.who,
    required this.onTap,
  });

  final Task task;
  final SlaStatus sla;
  final String? who;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = SlaStyle.of(sla);
    final ago = Formatters.timeAgo(task.updatedAt);
    final subtitle = task.isCompleted
        ? 'Completed by ${who ?? 'someone'} · $ago'
        : '${task.status.label} · ${who ?? 'Unassigned'} · $ago';

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      onTap: onTap,
      child: Row(
        children: [
          IconTile(
            icon: style.icon,
            color: style.color,
            background: style.soft,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: AppText.caption.copyWith(fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SoftPill(
            label: sla.label,
            color: style.color,
            background: style.soft,
          ),
        ],
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: AppColors.primarySoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0x1A6356D9)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 32,
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
