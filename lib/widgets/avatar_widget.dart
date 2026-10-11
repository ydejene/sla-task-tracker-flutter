import 'package:flutter/material.dart';
import '../models/team_member.dart';

class AvatarWidget extends StatelessWidget {
  final String initials;
  final String colorToken;
  final double radius;
  final double? fontSize;

  const AvatarWidget({
    super.key,
    required this.initials,
    required this.colorToken,
    this.radius = 18.0, // Default to ~medium (36x36)
    this.fontSize,
  });
  
  factory AvatarWidget.fromMember(TeamMember member, {double radius = 18.0, double? fontSize}) {
    return AvatarWidget(
      initials: member.initials,
      colorToken: member.avatarColor,
      radius: radius,
      fontSize: fontSize,
    );
  }

  Color _getBackgroundColor() {
    switch (colorToken) {
      case 'avatar-mint': return const Color(0xFFDFF2E9);
      case 'avatar-blue': return const Color(0xFFE2EBFB);
      case 'avatar-violet': return const Color(0xFFEBE4FB); 
      case 'avatar-sand': return const Color(0xFFF3EADB); 
      default: return const Color(0xFFE8E8EF); // --line fallback
    }
  }

  Color _getTextColor() {
    switch (colorToken) {
      case 'avatar-mint': return const Color(0xFF267A54);
      case 'avatar-blue': return const Color(0xFF3D609B);
      case 'avatar-violet': return const Color(0xFF694A9D);
      case 'avatar-sand': return const Color(0xFF8B6532);
      default: return const Color(0xFF666778); // --text-soft fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveFontSize = fontSize ?? (radius * 0.8);
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: _getTextColor(),
          fontWeight: FontWeight.bold,
          fontSize: effectiveFontSize,
          letterSpacing: -0.02 * effectiveFontSize,
        ),
      ),
    );
  }
}

