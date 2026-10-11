import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../utils/date_format.dart';
import 'avatar_widget.dart';
import 'priority_badge.dart';
import 'sla_badge.dart';
import 'status_badge.dart';
import 'task_colors.dart';

/// Task summary card used on the Dashboard and Tasks screens.
/// The background is tinted with the SLA color, and the SLA status is passed
/// in (calculated by TaskService.getSlaStatus), never read from the database.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.slaStatus,
    this.assignee,
    this.onTap,
  });

  final Task task;
  final SlaStatus slaStatus;
  final TeamMember? assignee;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final deadlineColor = switch (slaStatus) {
      SlaStatus.overdue => TaskColors.overdue,
      SlaStatus.atRisk => TaskColors.atRiskText,
      _ => TaskColors.cardDetail,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: SlaBadge.softColorFor(slaStatus),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: SlaBadge.borderColorFor(slaStatus)),
        boxShadow: const [
          BoxShadow(
            color: TaskColors.cardShadow,
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
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
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: TaskColors.heading,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFFAAA8B6),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(status: task.status),
                    SlaBadge(status: slaStatus, compact: true),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0x17505062),
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    if (assignee != null)
                      AvatarWidget.fromMember(
                        assignee!,
                        radius: 13.5,
                        fontSize: 8.5,
                      )
                    else
                      const CircleAvatar(
                        radius: 13.5,
                        backgroundColor: TaskColors.iconBackground,
                        child: Icon(
                          Icons.person_outline,
                          size: 14,
                          color: TaskColors.muted,
                        ),
                      ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        assignee?.name ?? 'Unassigned',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: TaskColors.cardDetail,
                        ),
                      ),
                    ),
                    PriorityBadge(priority: task.priority),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: deadlineColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatDeadline(task.deadline),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: deadlineColor,
                      ),
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
