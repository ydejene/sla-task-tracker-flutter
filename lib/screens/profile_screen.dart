import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../utils/date_format.dart';
import '../widgets/priority_badge.dart';
import '../widgets/sla_badge.dart';
import '../widgets/status_badge.dart';
import '../widgets/task_colors.dart';
import 'task_details_screen.dart';
import 'user_selection_screen.dart';

class ProfileScreen extends StatefulWidget {
  final TeamMember currentUser;
  final TeamMember? memberToView;

  const ProfileScreen({super.key, required this.currentUser, this.memberToView});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final TaskService _taskService = TaskService();

  bool _isLoading = true;
  List<Task> _memberTasks = [];

  TeamMember get _displayMember => widget.memberToView ?? widget.currentUser;
  bool get _isViewingSelf => widget.memberToView == null || widget.memberToView?.id == widget.currentUser.id;

  @override
  void initState() {
    super.initState();
    loadMemberTasks();
  }

  Future<void> loadMemberTasks() async {
    try {
      final allTasks = await _taskService.getAllTasks();
      if (mounted) {
        setState(() {
          _memberTasks = allTasks.where((t) => t.assignedTo == _displayMember.id).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tasks: $e')),
        );
      }
    }
  }

  /// Opens Task Details and reloads the list if the task was changed there.
  Future<void> _openTask(Task task) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TaskDetailsScreen(taskId: task.id)),
    );
    if (changed == true && mounted) loadMemberTasks();
  }

  void _switchUser() {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UserSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final activeTasks = _memberTasks.where((t) => t.status != TaskStatus.completed).toList();
    final completedCount = _memberTasks.length - activeTasks.length;
    final workloadLevel = _taskService.getWorkloadLevel(activeTasks.length);
    final bars = _taskService.getWorkloadBars(workloadLevel);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: loadMemberTasks,
        color: AppTheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(31),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                padding: const EdgeInsets.only(bottom: 1),
                child: Container(
                  padding: EdgeInsets.fromLTRB(21, MediaQuery.of(context).padding.top + 28, 21, 24),
                  decoration: const BoxDecoration(
                    color: AppTheme.chrome,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          !_isViewingSelf
                              ? GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    width: 37,
                                    height: 37,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(178),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppTheme.primary.withAlpha(31)),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryDeep, size: 16),
                                  ),
                                )
                              : const Text(
                                  'Profile',
                                  style: TextStyle(
                                    color: AppTheme.primaryDeep,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          if (_isViewingSelf)
                            GestureDetector(
                              onTap: _switchUser,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primarySoft,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Row(
                                  children: [
                                    Text(
                                      'Switch User',
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.swap_horiz, size: 12, color: AppTheme.primary),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withAlpha(209), width: 4), // 0.82
                          boxShadow: const [BoxShadow(color: Color(0x232A2458), blurRadius: 16, offset: Offset(0, 6))], // 0.14
                        ),
                        child: AvatarWidget.fromMember(_displayMember, radius: 35, fontSize: 17),
                      ),
                      const SizedBox(height: 11),
                      Text(
                        _displayMember.name,
                        style: const TextStyle(
                          color: AppTheme.text,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _displayMember.role,
                        style: const TextStyle(
                          color: Color(0xFF67637D),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(21, 22, 21, 116),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      border: Border.all(color: const Color(0x0F202030)), // 0.06
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [BoxShadow(color: Color(0x0A1D1D2F), blurRadius: 22, offset: Offset(0, 6))],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                              iconPath: Icons.assignment_outlined,
                              iconBg: AppTheme.primarySoft,
                              iconColor: AppTheme.primary,
                              count: _memberTasks.length,
                              label: 'Assigned',
                            ),
                          ),
                          const VerticalDivider(width: 1, thickness: 1, color: AppTheme.line),
                          Expanded(
                            child: _StatItem(
                              iconPath: Icons.check_circle_outline,
                              iconBg: AppTheme.greenSoft,
                              iconColor: AppTheme.green,
                              count: completedCount,
                              label: 'Completed',
                            ),
                          ),
                          const VerticalDivider(width: 1, thickness: 1, color: AppTheme.line),
                          Expanded(
                            child: _StatItem(
                              iconPath: Icons.hourglass_bottom,
                              iconBg: AppTheme.amberSoft,
                              iconColor: AppTheme.amber,
                              count: activeTasks.length,
                              label: 'Active',
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 11),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0x0F202030)),
                      boxShadow: const [BoxShadow(color: Color(0x0A1D1D2F), blurRadius: 22, offset: Offset(0, 6))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Workload Level', style: TextStyle(color: AppTheme.textFaint, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                            const SizedBox(height: 3),
                            Text(workloadLevel, style: const TextStyle(color: AppTheme.text, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.32)),
                            const SizedBox(height: 1),
                            Text('${activeTasks.length} active tasks', style: const TextStyle(color: AppTheme.textFaint, fontSize: 10)),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(4, (index) {
                            final heights = [7.0, 11.0, 15.0, 19.0];
                            final isFilled = index < bars;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: 6,
                              height: heights[index],
                              decoration: BoxDecoration(
                                color: isFilled ? AppTheme.primary : AppTheme.primarySoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            );
                          }),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Assigned Tasks', style: TextStyle(color: AppTheme.text, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.32)),
                            const SizedBox(height: 3),
                            Text('${_memberTasks.length} ${_memberTasks.length == 1 ? "task" : "tasks"} currently assigned', style: const TextStyle(color: AppTheme.textFaint, fontSize: 11.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  if (_memberTasks.isEmpty)
                    const _EmptyAssignedTasks()
                  else
                    ..._memberTasks.map((t) => _ProfileTaskCard(
                          task: t,
                          member: _displayMember,
                          slaStatus: _taskService.getSlaStatus(t, now: DateTime.now()),
                          onTap: () => _openTask(t),
                        )),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData iconPath;
  final Color iconBg;
  final Color iconColor;
  final int count;
  final String label;

  const _StatItem({
    required this.iconPath,
    required this.iconBg,
    required this.iconColor,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(iconPath, color: iconColor, size: 17),
          ),
          const SizedBox(height: 6),
          Text(count.toString(), style: const TextStyle(color: AppTheme.text, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 1),
          Text(label, style: const TextStyle(color: AppTheme.textFaint, fontSize: 8.5)),
        ],
      ),
    );
  }
}

/// Task card from the design: tinted by SLA status, with the workflow status,
/// the SLA mark, and the assignee, priority and deadline in the footer.
class _ProfileTaskCard extends StatelessWidget {
  final Task task;
  final TeamMember member;
  final SlaStatus slaStatus;
  final VoidCallback onTap;

  const _ProfileTaskCard({
    required this.task,
    required this.member,
    required this.slaStatus,
    required this.onTap,
  });

  Color get _deadlineColor => switch (slaStatus) {
        SlaStatus.overdue => TaskColors.overdue,
        SlaStatus.atRisk => TaskColors.atRiskText,
        _ => TaskColors.cardDetail,
      };

  @override
  Widget build(BuildContext context) {
    const detailStyle = TextStyle(
      fontSize: 9.5,
      fontWeight: FontWeight.w500,
      color: TaskColors.cardDetail,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: SlaBadge.softColorFor(slaStatus),
          border: Border.all(color: SlaBadge.borderColorFor(slaStatus)),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(color: Color(0x0A1D1D2F), blurRadius: 18, offset: Offset(0, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      height: 1.35,
                      color: AppTheme.text,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFAAA8B6)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                StatusBadge(status: task.status),
                const SizedBox(width: 7),
                SlaBadge(status: slaStatus, compact: true),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 11),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0x17505062))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        AvatarWidget.fromMember(member, radius: 13.5, fontSize: 8.5),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            member.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: detailStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  PriorityBadge(priority: task.priority),
                  const SizedBox(width: 12),
                  Icon(Icons.calendar_today_outlined, size: 14, color: _deadlineColor),
                  const SizedBox(width: 4),
                  Text(
                    formatDeadline(task.deadline),
                    style: detailStyle.copyWith(color: _deadlineColor),
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

/// Empty state from the design: white card, dashed border, purple icon.
class _EmptyAssignedTasks extends StatelessWidget {
  const _EmptyAssignedTasks();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: const _DashedBorderPainter(color: Color(0xFFD7D6E0), radius: 15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fact_check_outlined, size: 23, color: AppTheme.primary),
            SizedBox(height: 6),
            Text(
              'No assigned tasks',
              style: TextStyle(fontSize: 12, color: AppTheme.textSoft),
            ),
            SizedBox(height: 6),
            Text(
              'This member’s workload is currently clear.',
              style: TextStyle(fontSize: 10.5, color: AppTheme.textFaint),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), paint);
        distance += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
