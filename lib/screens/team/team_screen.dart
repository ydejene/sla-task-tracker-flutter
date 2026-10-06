import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../models/team_member.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/member_avatar.dart';
import '../navigation.dart';

/// Screen 6 — the project team and each member's task load.
class TeamScreen extends StatefulWidget {
  const TeamScreen({
    super.key,
    required this.onChanged,
    required this.onOpenProfile,
  });

  final VoidCallback onChanged;
  final VoidCallback onOpenProfile;

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  Future<void> _openMember(TeamMember m) async {
    await AppNavigation.openMember(context, m.id);
    if (!mounted) return;
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final members = scope.team.members;
    final me = scope.team.currentUser;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ScreenHeader(
          title: 'Team',
          subtitle: '${members.length} people on your delivery team',
          trailing: GestureDetector(
            onTap: widget.onOpenProfile,
            child: MemberAvatar(member: me, size: 50, ring: true, online: true),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            children: [
              const SectionHeader(
                title: 'Team members',
                subtitle: 'View ownership and current task load',
              ),
              for (final m in members)
                _MemberCard(
                  member: m,
                  isMe: m.id == me?.id,
                  openCount: scope.tasks.statsFor(m.id).active,
                  onTap: () => _openMember(m),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.isMe,
    required this.openCount,
    required this.onTap,
  });

  final TeamMember member;
  final bool isMe;
  final int openCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          MemberAvatar(member: member, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      const CountPill(label: 'You'),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(member.role, style: AppText.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$openCount',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                openCount == 1 ? 'open task' : 'open tasks',
                style: AppText.caption.copyWith(fontSize: 10.5),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.chevron),
        ],
      ),
    );
  }
}
