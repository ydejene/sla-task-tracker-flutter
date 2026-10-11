import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../theme/app_theme.dart';
import 'avatar_widget.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final SlaStatus slaStatus;
  final TeamMember? assignee;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.slaStatus,
    this.assignee,
    this.onTap,
  });

  static String formatDeadline(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $ampm';
    if (isToday) {
      return 'Today, $timeStr';
    }
    final today = DateTime.utc(now.year, now.month, now.day);
    final daysAway = DateTime.utc(dt.year, dt.month, dt.day).difference(today).inDays;
    if (daysAway == 1) return 'Tomorrow, $timeStr';
    if (daysAway == -1) return 'Yesterday, $timeStr';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, $timeStr';
  }

  Color _getSurfaceBg(SlaStatus sla) {
    switch (sla) {
      case SlaStatus.onTrack:
        return Color.alphaBlend(AppTheme.blue.withAlpha(15), AppTheme.surface);
      case SlaStatus.atRisk:
        return Color.alphaBlend(AppTheme.amber.withAlpha(18), AppTheme.surface);
      case SlaStatus.overdue:
        return Color.alphaBlend(AppTheme.red.withAlpha(15), AppTheme.surface);
      case SlaStatus.completed:
        return Color.alphaBlend(AppTheme.green.withAlpha(15), AppTheme.surface);
    }
  }

  Color _getBorderColor(SlaStatus sla) {
    switch (sla) {
      case SlaStatus.onTrack:
        return Color.alphaBlend(AppTheme.blue.withAlpha(33), AppTheme.surface);
      case SlaStatus.atRisk:
        return Color.alphaBlend(AppTheme.amber.withAlpha(36), AppTheme.surface);
      case SlaStatus.overdue:
        return Color.alphaBlend(AppTheme.red.withAlpha(33), AppTheme.surface);
      case SlaStatus.completed:
        return Color.alphaBlend(AppTheme.green.withAlpha(33), AppTheme.surface);
    }
  }

  IconData _getSlaIcon(SlaStatus sla) {
    switch (sla) {
      case SlaStatus.onTrack:
        return Icons.check;
      case SlaStatus.atRisk:
        return Icons.access_time_rounded;
      case SlaStatus.overdue:
        return Icons.priority_high_rounded;
      case SlaStatus.completed:
        return Icons.check_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final slaColor = AppTheme.getSlaColor(slaStatus);
    final bgColor = _getSurfaceBg(slaStatus);
    final borderColor = _getBorderColor(slaStatus);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A1D1D2F),
              blurRadius: 18,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title + Chevron
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.015 * 13.5,
                      height: 1.35,
                      color: AppTheme.text,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Color(0xFFAAA8B6),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Statuses Row: Neutral Status + SlaMark
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x17707080),
                    border: Border.all(color: const Color(0x14707080)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    task.status.value,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF686878),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: slaColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _getSlaIcon(slaStatus),
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      slaStatus.value,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: slaColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 11),
            const Divider(color: Color(0x17505062), height: 1, thickness: 1),
            const SizedBox(height: 11),

            // Details Footer
            Row(
              children: [
                // Assignee
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (assignee != null)
                        AvatarWidget.fromMember(assignee!, radius: 10, fontSize: 8.5)
                      else
                        const AvatarWidget(
                          initials: '?',
                          colorToken: 'default',
                          radius: 10,
                          fontSize: 8.5,
                        ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          assignee?.name ?? 'Unassigned',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF747483),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Priority
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_outlined, size: 14, color: Color(0xFF747483)),
                    const SizedBox(width: 4),
                    Text(
                      task.priority.value,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF747483),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Deadline
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: (slaStatus == SlaStatus.overdue || slaStatus == SlaStatus.atRisk)
                          ? slaColor
                          : const Color(0xFF747483),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatDeadline(task.deadline),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: (slaStatus == SlaStatus.overdue || slaStatus == SlaStatus.atRisk)
                            ? slaColor
                            : const Color(0xFF747483),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
