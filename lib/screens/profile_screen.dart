import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import 'user_selection_screen.dart';

class ProfileScreen extends StatefulWidget {
  final TeamMember currentUser;
  final TeamMember? memberToView;

  const ProfileScreen({
    super.key,
    required this.currentUser,
    this.memberToView,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TaskService _taskService = TaskService();

  bool _isLoading = true;
  List<Task> _memberTasks = [];

  TeamMember get _displayMember => widget.memberToView ?? widget.currentUser;
  bool get _isViewingSelf => widget.memberToView == null || widget.memberToView?.id == widget.currentUser.id;

  @override
  void initState() {
    super.initState();
    _loadMemberTasks();
  }

  Future<void> _loadMemberTasks() async {
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

  String _getWorkloadLevel(int active) {
    if (active <= 1) return 'Light';
    if (active <= 2) return 'Balanced'; 
    if (active <= 4) return 'Focused';
    return 'Full';
  }

  int _getWorkloadBars(String level) {
    switch (level) {
      case 'Light': return 1;
      case 'Balanced': return 2;
      case 'Focused': return 3;
      case 'Full': return 4;
      default: return 1;
    }
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
    final workloadLevel = _getWorkloadLevel(activeTasks.length);
    final bars = _getWorkloadBars(workloadLevel);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(21, MediaQuery.of(context).padding.top + 28, 21, 24),
              decoration: BoxDecoration(
                color: AppTheme.chrome,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: AppTheme.primary.withAlpha(31))),
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
                    child: AvatarWidget.fromMember(_displayMember, radius: 35),
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
                    border: Border.all(color: const Color(0x0F202030)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: AppTheme.primarySoft,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.trending_up, color: AppTheme.primary, size: 19),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Current workload', style: TextStyle(color: AppTheme.textFaint, fontSize: 9)),
                            const SizedBox(height: 3),
                            Text(workloadLevel, style: const TextStyle(color: AppTheme.text, fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(4, (index) {
                          final isActive = index < bars;
                          return Container(
                            margin: const EdgeInsets.only(left: 3),
                            width: 4,
                            height: 7.0 + (4.0 * index),
                            decoration: BoxDecoration(
                              color: isActive ? AppTheme.primary : const Color(0xFFDCDAE7),
                              borderRadius: BorderRadius.circular(2),
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
                  ..._memberTasks.map((t) => _ProfileTaskCard(task: t)),
              ]),
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

  const _ProfileTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    // Local evaluation mapping instead of enum text.
    final sla = TaskService().getSlaStatus(task, now: DateTime.now());
    final slaColor = AppTheme.getSlaColor(sla);
    
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

    return Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), 
                decoration: BoxDecoration(color: slaColor.withAlpha(26), borderRadius: BorderRadius.circular(4)), 
                child: Text(
                  getSlaLabel(sla), 
                  style: TextStyle(color: slaColor, fontSize: 8.5, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

