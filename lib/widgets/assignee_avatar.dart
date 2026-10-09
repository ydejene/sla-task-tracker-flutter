import 'package:flutter/material.dart';

import '../models/team_member.dart';
import 'task_colors.dart';

/// Small round avatar with the member's initials.
/// TODO: delete this file and use the shared Avatar widget once it is on dev.
class AssigneeAvatar extends StatelessWidget {
  const AssigneeAvatar({super.key, required this.member, this.radius = 14});

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
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w800,
          color: TaskColors.avatarForeground(background),
        ),
      ),
    );
  }
}
