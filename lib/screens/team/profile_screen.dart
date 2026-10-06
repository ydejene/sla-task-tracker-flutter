import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../controllers/task_controller.dart';
import '../../models/task.dart';
import '../../models/team_member.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/task_card.dart';
import '../navigation.dart';

/// Profile tab — the current user's own profile.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _resetDemo() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset demo data?'),
        content: const Text(
          'All tasks will be replaced with the original sample tasks. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.overdue),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final scope = AppScope.of(context);
    await scope.tasks.resetDemoData();
    await scope.team.loadMembers();
    if (!mounted) return;
    setState(() {});
    widget.onChanged();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Demo data restored')));
  }

  @override
  Widget build(BuildContext context) {
    final me = AppScope.of(context).team.currentUser;
    if (me == null) return const SizedBox.shrink();
    return ProfileView(
      member: me,
      isCurrentUser: true,
      onChanged: () {
        setState(() {});
        widget.onChanged();
      },
      footer: Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Switch user',
              icon: Icons.swap_horiz_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: () {
                AppScope.of(context).team.clearUser();
                AppNavigation.switchUser(context);
              },
            ),
          ),
          TextButton.icon(
            onPressed: _resetDemo,
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('Reset demo data'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Screen 7 — profile of any team member, opened from the Team screen.
class MemberProfileScreen extends StatefulWidget {
  const MemberProfileScreen({super.key, required this.memberId});

  final String memberId;

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final team = AppScope.of(context).team;
    final member = team.getMember(widget.memberId);
    return Scaffold(
      body: member == null
          ? const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Member not found',
              message: 'This team member no longer exists.',
            )
          : ProfileView(
              member: member,
              isCurrentUser: member.id == team.currentUser?.id,
              onBack: () => Navigator.of(context).pop(),
              onChanged: () => setState(() {}),
            ),
    );
  }
}

/// Shared profile layout used by both the Profile tab and member profiles.
class ProfileView extends StatelessWidget {
  const ProfileView({
    super.key,
    required this.member,
    required this.isCurrentUser,
    required this.onChanged,
    this.onBack,
    this.footer,
  });

  final TeamMember member;
  final bool isCurrentUser;
  final VoidCallback onChanged;
  final VoidCallback? onBack;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).tasks;
    final stats = controller.statsFor(member.id);
    final assigned = controller.tasksFor(member.id)
      ..sort((a, b) {
        // Open work first, then by deadline.
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        return a.deadline.compareTo(b.deadline);
      });

    Future<void> openTask(Task t) async {
      await AppNavigation.openTask(context, t.id);
      onChanged();
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ScreenHeader(
          child: Column(
            children: [
              Row(
                children: [
                  if (onBack != null)
                    HeaderIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      onTap: onBack!,
                    )
                  else
                    const Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  const Spacer(),
                  if (isCurrentUser) const CountPill(label: 'Current user'),
                ],
              ),
              const SizedBox(height: 6),
              MemberAvatar(member: member, size: 80, ring: true),
              const SizedBox(height: 12),
              Text(
                member.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                member.role,
                style: const TextStyle(fontSize: 13, color: Color(0xFF67637D)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    _Stat(
                      icon: Icons.assignment_outlined,
                      color: AppColors.primary,
                      background: AppColors.primarySoft,
                      value: stats.assigned,
                      label: 'Assigned',
                    ),
                    _Stat(
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.completed,
                      background: AppColors.completedSoft,
                      value: stats.completed,
                      label: 'Completed',
                    ),
                    _Stat(
                      icon: Icons.bolt_rounded,
                      color: AppColors.atRisk,
                      background: AppColors.atRiskSoft,
                      value: stats.active,
                      label: 'Active',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _WorkloadCard(workload: stats.workload),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'Assigned Tasks',
                subtitle:
                    '${Formatters.plural(stats.active, 'task')} currently open',
              ),
              if (assigned.isEmpty)
                const AppCard(
                  child: Text('No tasks assigned yet.', style: AppText.body),
                )
              else
                for (final t in assigned)
                  TaskCard(
                    task: t,
                    sla: controller.slaOf(t),
                    assignee: member,
                    onTap: () => openTask(t),
                  ),
              ?footer,
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.background,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          IconTile(icon: icon, color: color, background: background, size: 34),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          Text(label, style: AppText.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

class _WorkloadCard extends StatelessWidget {
  const _WorkloadCard({required this.workload});

  final Workload workload;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          const IconTile(
            icon: Icons.speed_rounded,
            color: AppColors.primary,
            background: AppColors.primarySoft,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current workload',
                  style: AppText.caption.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  workload.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 4; i++)
                Container(
                  margin: const EdgeInsets.only(left: 3),
                  width: 5,
                  height: 9.0 + i * 5,
                  decoration: BoxDecoration(
                    color: i < workload.bars
                        ? AppColors.primary
                        : const Color(0xFFDCDAE7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
