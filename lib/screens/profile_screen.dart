import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/avatar_widget.dart';
import 'task_details_screen.dart';
import 'user_selection_screen.dart';

class ProfileScreen extends StatefulWidget {
  final TeamMember currentUser;
  final TeamMember? memberToView;
  final VoidCallback? onBack;

  const ProfileScreen({super.key, required this.currentUser, this.memberToView, this.onBack});

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

    final onBack = widget.onBack ??
        (Navigator.of(context).canPop() ? () => Navigator.of(context).pop() : null);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(
            onBack: onBack,
            actions: [
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
            child: Text(
              _isViewingSelf ? 'Profile' : _displayMember.firstName,
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 23,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.035 * 23,
                height: 1.2,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
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
                  padding: EdgeInsets.fromLTRB(21, 18, 21, 24),
                  decoration: const BoxDecoration(
                    color: AppTheme.chrome,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
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
              padding: const EdgeInsets.fromLTRB(21, 22, 21, 40),
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
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      alignment: Alignment.center,
                      child: const Column(
                        children: [
                          Icon(Icons.assignment, size: 23, color: AppTheme.textFaint),
                          SizedBox(height: 8),
                          Text('No assigned tasks', style: TextStyle(color: AppTheme.text, fontSize: 12.5, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('This member’s workload is currently clear.', style: TextStyle(color: AppTheme.textFaint, fontSize: 11.5)),
                        ],
                      ),
                    )
                  else
                    ..._memberTasks.map((t) => _ProfileTaskCard(
                          task: t,
                          slaStatus: _taskService.getSlaStatus(t, now: DateTime.now()),
                          onTap: () async {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TaskDetailsScreen(
                                  taskId: t.id,
                                  currentUser: widget.currentUser,
                                ),
                              ),
                            );
                            if (changed == true) {
                              loadMemberTasks();
                            }
                          },
                        )),
                ]),
              ),
            ),
          ],
        ),
      ),
          ),
        ],
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

class _ProfileTaskCard extends StatelessWidget {
  final Task task;
  final SlaStatus slaStatus;
  final VoidCallback? onTap;

  const _ProfileTaskCard({
    required this.task,
    required this.slaStatus,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final slaColor = AppTheme.getSlaColor(slaStatus);
    
    String getSlaLabel(SlaStatus status) {
      switch (status) {
        case SlaStatus.onTrack: return 'ON TRACK';
        case SlaStatus.atRisk: return 'AT RISK';
        case SlaStatus.overdue: return 'OVERDUE';
        case SlaStatus.completed: return 'COMPLETED';
      }
    }

    String getStatusLabel(TaskStatus status) {
      switch (status) {
        case TaskStatus.todo: return 'TODO';
        case TaskStatus.inProgress: return 'IN PROGRESS';
        case TaskStatus.paused: return 'PAUSED';
        case TaskStatus.completed: return 'COMPLETED';
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0x0F202030)),
          boxShadow: const [BoxShadow(color: Color(0x0A1D1D2F), blurRadius: 22, offset: Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(color: AppTheme.text, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.35),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: AppTheme.textFaint),
              ],
            ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                getStatusLabel(task.status), 
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textSoft)
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: slaColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: slaColor.withAlpha(51)),
                ),
                child: Text(
                  getSlaLabel(slaStatus),
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: slaColor),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}
