import 'package:flutter/material.dart';

import '../models/team_member.dart';
import '../theme/app_theme.dart';

/// Circular initials avatar. Colour comes from the member's `avatar` key.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.member,
    this.size = 38,
    this.ring = false,
    this.online = false,
  });

  final TeamMember? member;
  final double size;

  /// White ring and shadow, used for the large header avatars.
  final bool ring;

  /// Green presence dot (current user).
  final bool online;

  static const _palette = <String, (Color fg, Color bg)>{
    'green': (Color(0xFF267A54), Color(0xFFDFF2E9)),
    'blue': (Color(0xFF3D609B), Color(0xFFE2EBFB)),
    'purple': (Color(0xFF694A9D), Color(0xFFEBE4FB)),
    'amber': (Color(0xFF8B6532), Color(0xFFF3EADB)),
    'rose': (Color(0xFF9B3D5E), Color(0xFFFBE4EC)),
    'teal': (Color(0xFF2F7C80), Color(0xFFDDF1F2)),
  };

  @override
  Widget build(BuildContext context) {
    final m = member;
    final colors =
        _palette[m?.avatar] ?? (AppColors.textMuted, AppColors.surfaceMuted);
    final ringWidth = ring ? (size > 60 ? 4.0 : 3.0) : 0.0;

    final circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.$2,
        shape: BoxShape.circle,
        border: ring
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.82),
                width: ringWidth,
              )
            : null,
        boxShadow: ring ? AppShadows.avatar : null,
      ),
      child: m == null
          ? Icon(
              Icons.person_outline_rounded,
              size: size * 0.5,
              color: colors.$1,
            )
          : Text(
              m.initials,
              style: TextStyle(
                fontSize: size * 0.3,
                fontWeight: FontWeight.w700,
                color: colors.$1,
              ),
            ),
    );

    if (!online) return circle;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        circle,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: size * 0.24,
            height: size * 0.24,
            decoration: BoxDecoration(
              color: AppColors.completed,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
