import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/team_member.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'member_avatar.dart';
import 'priority_badge.dart';
import 'status_badge.dart';

/// Task summary card used on the Dashboard, Task List and Profiles.
/// The card background is tinted with the task's SLA colour.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.sla,
    required this.assignee,
    this.onTap,
  });

  final Task task;
  final SlaStatus sla;
  final TeamMember? assignee;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = SlaStyle.of(sla);
    final deadlineColor = switch (sla) {
      SlaStatus.overdue => AppColors.overdue,
      SlaStatus.atRisk => AppColors.atRiskText,
      _ => AppColors.meta,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: style.tint,
        border: Border.all(color: style.tintBorder),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.cardTitle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.chevron,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(status: task.status),
                    SlaBadge(status: sla),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0x17505062)),
                const SizedBox(height: 11),
                Row(
                  children: [
                    MemberAvatar(member: assignee, size: 28),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        assignee?.name ?? 'Unassigned',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.meta,
                      ),
                    ),
                    PriorityBadge(priority: task.priority),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: deadlineColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      Formatters.deadline(task.deadline),
                      style: AppText.meta.copyWith(color: deadlineColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
