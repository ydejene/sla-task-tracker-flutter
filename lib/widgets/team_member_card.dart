import 'package:flutter/material.dart';

import '../models/team_member.dart';
import '../theme/app_theme.dart';
import 'avatar_widget.dart';

class TeamMemberCard extends StatelessWidget {
  final TeamMember member;
  final bool isCurrentUser;
  final int assignedCount;
  final VoidCallback? onTap;

  const TeamMemberCard({
    super.key,
    required this.member,
    this.isCurrentUser = false,
    required this.assignedCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x0F202030)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x091D1D2F),
              blurRadius: 18,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            AvatarWidget.fromMember(member, radius: 17, fontSize: 10),
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
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.text,
                          ),
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primarySoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    member.role,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textFaint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$assignedCount',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.text,
                  ),
                ),
                Text(
                  assignedCount == 1 ? 'task' : 'tasks',
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: AppTheme.textFaint,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right,
              size: 17,
              color: Color(0xFFAAA8B6),
            ),
          ],
        ),
      ),
    );
  }
}
