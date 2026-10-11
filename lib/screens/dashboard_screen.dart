import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/sla_badge.dart';
import '../widgets/task_card.dart';
import 'task_details_screen.dart';
import 'task_form_screen.dart';

/// Overview tab: SLA health summary, tasks that need attention and recent work.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.currentUser});

  /// Used for the greeting and header avatar.
  final TeamMember? currentUser;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TaskService _taskService = TaskService();

  bool _isLoading = true;
  List<Task> _tasks = [];
  Map<String, TeamMember> _membersById = {};

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final tasks = await _taskService.getAllTasks();
      final members = await _taskService.getAllMembers();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _membersById = {for (final m in members) m.id: m};
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load tasks: $e')));
    }
  }

  // SLA status is always calculated from the task, never stored.
  SlaStatus _slaOf(Task task) =>
      _taskService.getSlaStatus(task, now: DateTime.now());

  Future<void> _openTask(Task task) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TaskDetailsScreen(taskId: task.id)),
    );
    if (changed == true) _loadData();
  }

  Future<void> _createTask() async {
    final created = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const TaskFormScreen()));
    if (created == true) _loadData();
  }

  String _greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final counts = {for (final s in SlaStatus.values) s: 0};
    for (final task in _tasks) {
      counts[_slaOf(task)] = counts[_slaOf(task)]! + 1;
    }

    // Overdue first, then At Risk, then the earliest deadline.
    final attention =
        _tasks.where((t) {
          final sla = _slaOf(t);
          return sla == SlaStatus.overdue || sla == SlaStatus.atRisk;
        }).toList()..sort((a, b) {
          final rankA = _slaOf(a) == SlaStatus.overdue ? 0 : 1;
          final rankB = _slaOf(b) == SlaStatus.overdue ? 0 : 1;
          if (rankA != rankB) return rankA - rankB;
          return a.deadline.compareTo(b.deadline);
        });

    final recent = [..._tasks]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final activeCount = _tasks
        .where((t) => t.status != TaskStatus.completed)
        .length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _createTask,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        tooltip: 'New task',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(21, 24, 21, 96),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SectionTitle(
                    title: 'SLA Health',
                    subtitle:
                        '$activeCount active ${activeCount == 1 ? 'task' : 'tasks'} · ${_tasks.length} tracked',
                  ),
                  const SizedBox(height: 13),
                  _HealthCard(counts: counts, total: _tasks.length),
                  const SizedBox(height: 26),
                  _SectionTitle(
                    title: 'Needs Attention',
                    subtitle: 'Prioritized by urgency',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.redSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${attention.length} ${attention.length == 1 ? 'task' : 'tasks'}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.red,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  if (attention.isEmpty)
                    const _EmptyNote(
                      icon: Icons.check_circle_outline,
                      text: 'All caught up — no tasks are at risk or overdue.',
                    )
                  else
                    ...attention
                        .take(3)
                        .map(
                          (t) => TaskCard(
                            task: t,
                            slaStatus: _slaOf(t),
                            assignee: _membersById[t.assignedTo],
                            onTap: () => _openTask(t),
                          ),
                        ),
                  const SizedBox(height: 16),
                  const _SectionTitle(title: 'Recent Work'),
                  const SizedBox(height: 13),
                  if (recent.isEmpty)
                    const _EmptyNote(
                      icon: Icons.assignment_outlined,
                      text: 'No tasks yet. Tap + to create the first one.',
                    )
                  else
                    ...recent
                        .take(3)
                        .map(
                          (t) => _RecentItem(
                            task: t,
                            slaStatus: _slaOf(t),
                            subtitle: _recentSubtitle(t),
                            onTap: () => _openTask(t),
                          ),
                        ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _recentSubtitle(Task task) {
    final who = _membersById[task.assignedTo]?.firstName ?? 'Unassigned';
    final ago = _timeAgo(task.updatedAt);
    if (task.status == TaskStatus.completed) {
      return 'Completed by $who · $ago';
    }
    return '${task.status.value} · $who · $ago';
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final user = widget.currentUser;
    final date =
        '${_weekdays[now.weekday - 1]}, ${_months[now.month - 1]} ${now.day}';
    final greeting = user == null
        ? _greeting(now)
        : '${_greeting(now)}, ${user.firstName}';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(31),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: const EdgeInsets.only(bottom: 1),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          21,
          MediaQuery.of(context).padding.top + 22,
          21,
          20,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.chrome,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDeep,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    greeting,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Here’s where your team stands today.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF5E5B78)),
                  ),
                ],
              ),
            ),
            if (user != null)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withAlpha(209),
                    width: 3,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x232A2458),
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: AvatarWidget.fromMember(user, radius: 20, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.32,
                  color: AppTheme.text,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textFaint,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Donut chart, headline and the four SLA counts.
class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.counts, required this.total});

  final Map<SlaStatus, int> counts;
  final int total;

  @override
  Widget build(BuildContext context) {
    final healthy = counts[SlaStatus.onTrack]! + counts[SlaStatus.completed]!;
    final attention = counts[SlaStatus.atRisk]! + counts[SlaStatus.overdue]!;
    final percent = total == 0 ? 100 : (healthy * 100 / total).round();

    final String headline;
    if (total == 0) {
      headline = 'No tasks yet';
    } else if (attention == 0) {
      headline = 'Everything is on track';
    } else if (percent >= 70) {
      headline = 'Your team is in good shape';
    } else {
      headline = 'Some work needs a push';
    }
    final message = attention == 0
        ? 'No tasks need attention right now.'
        : '$attention ${attention == 1 ? 'task needs' : 'tasks need'} attention to keep this week on track.';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0x0E202030)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B1D1D2F),
            blurRadius: 22,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Row(
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: CustomPaint(
                    painter: _DonutPainter(counts),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$percent%',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.text,
                            ),
                          ),
                          const Text(
                            'healthy',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppTheme.textFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 17),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 21,
                            height: 21,
                            decoration: BoxDecoration(
                              color: AppTheme.primarySoft,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Icon(
                              Icons.monitor_heart_outlined,
                              size: 14,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Overall task health',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        headline,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppTheme.line),
          IntrinsicHeight(
            child: Row(
              children: [
                _CountCell(
                  status: SlaStatus.onTrack,
                  count: counts[SlaStatus.onTrack]!,
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppTheme.line,
                ),
                _CountCell(
                  status: SlaStatus.atRisk,
                  count: counts[SlaStatus.atRisk]!,
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppTheme.line),
          IntrinsicHeight(
            child: Row(
              children: [
                _CountCell(
                  status: SlaStatus.overdue,
                  count: counts[SlaStatus.overdue]!,
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppTheme.line,
                ),
                _CountCell(
                  status: SlaStatus.completed,
                  count: counts[SlaStatus.completed]!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountCell extends StatelessWidget {
  const _CountCell({required this.status, required this.count});

  final SlaStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = SlaBadge.colorFor(status);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(SlaBadge.iconFor(status), size: 14, color: color),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                status.value,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSoft),
              ),
            ),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.text,
              ),
            ),
          ],
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
    const stroke = 9.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppTheme.line;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;

    final segments = _order.where((s) => counts[s]! > 0).length;
    final gap = segments > 1 ? 0.12 : 0.0;
    var start = -math.pi / 2;
    for (final status in _order) {
      final count = counts[status]!;
      if (count == 0) continue;
      final sweep = math.pi * 2 * count / total;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = SlaBadge.colorFor(status);
      canvas.drawArc(
        rect,
        start + gap / 2,
        math.max(sweep - gap, 0.01),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) => true;
}

class _RecentItem extends StatelessWidget {
  const _RecentItem({
    required this.task,
    required this.slaStatus,
    required this.subtitle,
    required this.onTap,
  });

  final Task task;
  final SlaStatus slaStatus;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = SlaBadge.colorFor(slaStatus);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x0E202030)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B1D1D2F),
            blurRadius: 22,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: SlaBadge.softColorFor(slaStatus),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    SlaBadge.iconFor(slaStatus),
                    size: 16,
                    color: color,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppTheme.textFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: SlaBadge.softColorFor(slaStatus),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    slaStatus.value,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: SlaBadge.textColorFor(slaStatus),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x0E202030)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11.5, color: AppTheme.textSoft),
            ),
          ),
        ],
      ),
    );
  }
}
