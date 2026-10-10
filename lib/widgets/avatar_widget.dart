import 'package:flutter/material.dart';
import '../models/team_member.dart';

class AvatarWidget extends StatelessWidget {
  final String initials;
  final String colorToken;
  final double radius;

  const AvatarWidget({
    super.key,
    required this.initials,
    required this.colorToken,
    this.radius = 18.0, // Default to ~medium (36x36)
  });
  
  factory AvatarWidget.fromMember(TeamMember member, {double radius = 18.0}) {
    return AvatarWidget(
      initials: member.initials,
      colorToken: member.avatarColor,
      radius: radius,
    );
  }

  Color _getBackgroundColor() {
    switch (colorToken) {
      case 'avatar-mint': return const Color(0xFFDFF2E9);
      case 'avatar-blue': return const Color(0xFFE2EBFB);
      case 'avatar-violet': return const Color(0xFFEDE9FE); 
      case 'avatar-sand': return const Color(0xFFFDF5E6); 
      default: return const Color(0xFFE8E8EF); // --line fallback
    }
  }

  Color _getTextColor() {
    switch (colorToken) {
      case 'avatar-mint': return const Color(0xFF267A54);
      case 'avatar-blue': return const Color(0xFF3D609B);
      case 'avatar-violet': return const Color(0xFF5B21B6);
      case 'avatar-sand': return const Color(0xFF9C6644);
      default: return const Color(0xFF666778); // --text-soft fallback
    }
  }

  @override
  Widget build(BuildContext context) {
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
          fontSize: radius * 0.8, // Approximation based on sizes
          letterSpacing: -0.02,
        ),
      ),
    );
  }
}

