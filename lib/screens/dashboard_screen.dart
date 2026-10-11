import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/task_card.dart';
import 'task_details_screen.dart';
import 'task_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  final TeamMember currentUser;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onBack;

  const DashboardScreen({
    super.key,
    required this.currentUser,
    this.onOpenProfile,
    this.onBack,
  });

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final TaskService _taskService = TaskService();
  final DatabaseService _dbService = DatabaseService();

  List<Task> _tasks = [];
  Map<String, TeamMember> _teamMembersMap = {};
  bool _isLoading = true;

  String _attentionFilter = 'All'; // 'All', 'At Risk', 'Overdue'

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      final tasks = await _taskService.getAllTasks();
      final members = await _dbService.getAllTeamMembers();

      final membersMap = {for (var m in members) m.id: m};

      if (mounted) {
        setState(() {
          _tasks = tasks;
          _teamMembersMap = membersMap;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatTodayDate() {
    final now = DateTime.now();
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
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
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    // SLA analytics
    final activeTasks = _tasks.where((t) => t.status != TaskStatus.completed).toList();
    final completedTasks = _tasks.where((t) => t.status == TaskStatus.completed).toList();

    int onTrackCount = 0;
    int atRiskCount = 0;
    int overdueCount = 0;

    for (final task in activeTasks) {
      final sla = _taskService.computeSlaStatus(task);
      switch (sla) {
        case SlaStatus.onTrack:
          onTrackCount++;
          break;
        case SlaStatus.atRisk:
          atRiskCount++;
          break;
        case SlaStatus.overdue:
          overdueCount++;
          break;
        case SlaStatus.completed:
          break;
      }
    }

    final int totalActive = activeTasks.length;
    final int healthyPercentage = totalActive == 0
        ? 100
        : ((onTrackCount / totalActive) * 100).round();

    // Urgent tasks for "Needs Attention"
    final urgentTasks = activeTasks.where((task) {
      final sla = _taskService.computeSlaStatus(task);
      return sla == SlaStatus.atRisk || sla == SlaStatus.overdue;
    }).toList();

    // Sort by urgency: Overdue first, then At Risk, then earliest deadline
    urgentTasks.sort((a, b) {
      final slaA = _taskService.computeSlaStatus(a);
      final slaB = _taskService.computeSlaStatus(b);
      if (slaA == SlaStatus.overdue && slaB != SlaStatus.overdue) return -1;
      if (slaB == SlaStatus.overdue && slaA != SlaStatus.overdue) return 1;
      return a.deadline.compareTo(b.deadline);
    });

    final visibleAttentionTasks = urgentTasks.where((task) {
      if (_attentionFilter == 'All') return true;
      final sla = _taskService.computeSlaStatus(task);
      if (_attentionFilter == 'At Risk') return sla == SlaStatus.atRisk;
      if (_attentionFilter == 'Overdue') return sla == SlaStatus.overdue;
      return true;
    }).toList();

    // Recent work (most recently completed or updated task)
    Task? recentTask;
    if (completedTasks.isNotEmpty) {
      final sortedCompleted = List<Task>.from(completedTasks)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      recentTask = sortedCompleted.first;
    }

    final header = AppHeader(
      onBack: widget.onBack,
      actions: [
        HeaderAvatar(member: widget.currentUser, onTap: widget.onOpenProfile),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatTodayDate().toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primaryDeep,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08 * 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_greeting()},',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textSoft,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          Text(
            widget.currentUser.firstName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.text,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.035 * 23,
              height: 1.2,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
                padding: const EdgeInsets.fromLTRB(21, 22, 21, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1: SLA Health
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SLA Health',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.02 * 16,
                                color: AppTheme.text,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$totalActive active ${totalActive == 1 ? 'task' : 'tasks'}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textFaint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),

                    // Health Card
                    Container(
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
                          // Top Health Overview
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                // Circular Progress Ring
                                SizedBox(
                                  width: 84,
                                  height: 84,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 74,
                                        height: 74,
                                        child: CircularProgressIndicator(
                                          value: healthyPercentage / 100,
                                          backgroundColor: AppTheme.primarySoft,
                                          valueColor: const AlwaysStoppedAnimation<Color>(
                                            AppTheme.primary,
                                          ),
                                          strokeWidth: 7,
                                          strokeCap: StrokeCap.round,
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$healthyPercentage%',
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.03 * 17,
                                              height: 1.1,
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
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 17),

                                // Health Text Copy
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
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.auto_awesome,
                                              size: 13,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          const Text(
                                            'OVERALL TASK HEALTH',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.04 * 10,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        healthyPercentage >= 70
                                            ? 'Your team is in good shape'
                                            : overdueCount > 0
                                                ? 'Needs immediate action'
                                                : 'Some tasks need attention',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.025 * 15,
                                          height: 1.3,
                                          color: AppTheme.text,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        atRiskCount + overdueCount == 0
                                            ? 'All active tasks are currently on track.'
                                            : atRiskCount + overdueCount == 1
                                                ? '1 task needs attention to stay on track.'
                                                : '${atRiskCount + overdueCount} tasks need attention to stay on track.',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          height: 1.45,
                                          color: AppTheme.textSoft,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 2x2 Stats Grid with dividing lines
                          Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppTheme.line, width: 1),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCell(
                                        icon: Icons.trending_up,
                                        label: 'On Track',
                                        value: onTrackCount,
                                        color: AppTheme.blue,
                                        softColor: AppTheme.blueSoft,
                                      ),
                                    ),
                                    Container(width: 1, height: 52, color: AppTheme.line),
                                    Expanded(
                                      child: _buildStatCell(
                                        icon: Icons.hourglass_top_rounded,
                                        label: 'At Risk',
                                        value: atRiskCount,
                                        color: AppTheme.amber,
                                        softColor: AppTheme.amberSoft,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(height: 1, color: AppTheme.line),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCell(
                                        icon: Icons.warning_amber_rounded,
                                        label: 'Overdue',
                                        value: overdueCount,
                                        color: AppTheme.red,
                                        softColor: AppTheme.redSoft,
                                      ),
                                    ),
                                    Container(width: 1, height: 52, color: AppTheme.line),
                                    Expanded(
                                      child: _buildStatCell(
                                        icon: Icons.check_circle_outline_rounded,
                                        label: 'Completed',
                                        value: completedTasks.length,
                                        color: AppTheme.green,
                                        softColor: AppTheme.greenSoft,
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

                    const SizedBox(height: 27),

                    // Section 2: Needs Attention
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Needs Attention',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.02 * 16,
                                color: AppTheme.text,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Prioritized by urgency',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textFaint,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.redSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${_attentionFilter == 'All' ? '' : '$_attentionFilter · '}${visibleAttentionTasks.length} ${visibleAttentionTasks.length == 1 ? "task" : "tasks"}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),

                    if (visibleAttentionTasks.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0x0E202030)),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'No tasks currently need urgent attention.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSoft,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: visibleAttentionTasks.map((task) {
                          final sla = _taskService.computeSlaStatus(task);
                          final assignee = task.assignedTo != null
                              ? _teamMembersMap[task.assignedTo]
                              : null;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TaskCard(
                              task: task,
                              slaStatus: sla,
                              assignee: assignee,
                              onTap: () async {
                                final changed = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TaskDetailsScreen(
                                      taskId: task.id,
                                      currentUser: widget.currentUser,
                                    ),
                                  ),
                                );
                                if (changed == true) {
                                  loadDashboardData();
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 25),

                    // Section 3: Recent Work
                    if (recentTask != null) ...[
                      const Text(
                        'Recent Work',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.02 * 16,
                          color: AppTheme.text,
                        ),
                      ),
                      const SizedBox(height: 11),
                      InkWell(
                        onTap: () async {
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailsScreen(
                                taskId: recentTask!.id,
                                currentUser: widget.currentUser,
                              ),
                            ),
                          );
                          if (changed == true) {
                            loadDashboardData();
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(13),
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
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppTheme.greenSoft,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: AppTheme.green,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recentTask.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.text,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _teamMembersMap[recentTask.assignedTo] == null
                                          ? 'Completed · ${_formatTimeAgo(recentTask.updatedAt)}'
                                          : 'Completed by ${_teamMembersMap[recentTask.assignedTo]!.firstName} · ${_formatTimeAgo(recentTask.updatedAt)}',
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
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppTheme.greenSoft,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Completed',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ),
        ),
        DraggableFab(
          onPressed: () async {
            final created = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => TaskFormScreen(currentUser: widget.currentUser),
              ),
            );
            if (created == true) {
              loadDashboardData();
            }
          },
        ),
      ],
    ),
    ),
    ],
  ),
  );
  }

  Widget _buildAttentionFilterButton() {
    final active = _attentionFilter != 'All';
    return PopupMenuButton<String>(
      tooltip: 'Filter needs attention',
      initialValue: _attentionFilter,
      offset: const Offset(0, 44),
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      onSelected: (v) => setState(() => _attentionFilter = v),
      itemBuilder: (_) => ['All', 'At Risk', 'Overdue']
          .map(
            (opt) => CheckedPopupMenuItem<String>(
              value: opt,
              checked: _attentionFilter == opt,
              height: 40,
              child: Text(
                opt,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          )
          .toList(),
      child: Container(
        width: 37,
        height: 37,
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.white.withAlpha(180),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x1F6356D9)),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.filter_list_rounded,
          size: 18,
          color: active ? Colors.white : AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildStatCell({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    required Color softColor,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSoft,
              ),
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.text,
            ),
          ),
        ],
      ),
    );
  }
}
