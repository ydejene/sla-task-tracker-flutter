import 'package:flutter/material.dart';

import '../models/team_member.dart';
import 'task_colors.dart';

/// Small round avatar with the member's initials (27px by default, like the design).
/// TODO: delete this file and use the shared Avatar widget once it is on dev.
class AssigneeAvatar extends StatelessWidget {
  const AssigneeAvatar({super.key, required this.member, this.radius = 13.5});

  final TeamMember member;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final background = TaskColors.avatarBackground(member.avatarColor);
    return CircleAvatar(
      radius: radius,
      backgroundColor: background,
      child: Text(
        member.initials,
        style: TextStyle(
          fontSize: radius * 0.63, // 8.5px on a 27px avatar
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02 * radius * 0.63,
          color: TaskColors.avatarForeground(background),
        ),
      ),
    );
  }
}
