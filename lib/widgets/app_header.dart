import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/team_member.dart';
import '../theme/app_theme.dart';
import 'avatar_widget.dart';

/// Small rounded back button used in every screen header.
class HeaderBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const HeaderBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(180),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x1F6356D9)),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.arrow_back_ios_new,
            size: 16,
            color: AppTheme.primaryDeep,
          ),
        ),
      ),
    );
  }
}

/// Sticky chrome header shared by all screens. Put it OUTSIDE the scrollable
/// area (e.g. as the first child of a Column above an Expanded scroll view)
/// so it stays pinned at the top.
class AppHeader extends StatelessWidget {
  /// If non-null, a back button is shown at the start of the header.
  final VoidCallback? onBack;

  /// Main content (titles) of the header.
  final Widget child;

  /// Widgets shown at the end of the title row (filter button, avatar, ...).
  final List<Widget> actions;

  /// Optional extra row under the title row (search bar, filter chips...).
  final Widget? bottom;

  const AppHeader({
    super.key,
    required this.child,
    this.onBack,
    this.actions = const [],
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = math.max(MediaQuery.of(context).padding.top, 24.0);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.chrome,
        border: Border(bottom: BorderSide(color: Color(0x1F6356D9), width: 1)),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.fromLTRB(21, topInset + 12, 21, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (onBack != null) ...[
                HeaderBackButton(onTap: onBack!),
                const SizedBox(width: 14),
              ],
              Expanded(child: child),
              for (final a in actions) ...[const SizedBox(width: 10), a],
            ],
          ),
          if (bottom != null) ...[const SizedBox(height: 14), bottom!],
        ],
      ),
    );
  }
}

/// A floating action button the user can drag anywhere inside its parent.
/// Place it as a child of a Stack that fills the area it may move in.
/// On release it snaps to the nearest left/right edge.
class DraggableFab extends StatefulWidget {
  final VoidCallback onPressed;
  final double size;
  final double margin;

  const DraggableFab({
    super.key,
    required this.onPressed,
    this.size = 56,
    this.margin = 16,
  });

  @override
  State<DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends State<DraggableFab> {
  Offset? _pos; // top-left, null until first layout (defaults to bottom-right)
  bool _dragging = false;

  Offset _clamp(Offset p, Size area) {
    final m = widget.margin;
    final maxX = math.max(m, area.width - widget.size - m);
    final maxY = math.max(m, area.height - widget.size - m);
    return Offset(p.dx.clamp(m, maxX), p.dy.clamp(m, maxY));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final area = Size(constraints.maxWidth, constraints.maxHeight);
      final pos = _clamp(
        _pos ??
            Offset(
              area.width - widget.size - widget.margin,
              area.height - widget.size - widget.margin,
            ),
        area,
      );

      return Stack(
        children: [
          AnimatedPositioned(
            duration: _dragging ? Duration.zero : const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            left: pos.dx,
            top: pos.dy,
            child: GestureDetector(
              onTap: widget.onPressed,
              onPanStart: (_) => setState(() => _dragging = true),
              onPanUpdate: (d) {
                setState(() => _pos = _clamp(pos + d.delta, area));
              },
              onPanEnd: (_) {
                final snapLeft = pos.dx + widget.size / 2 < area.width / 2;
                setState(() {
                  _dragging = false;
                  _pos = Offset(
                    snapLeft
                        ? widget.margin
                        : area.width - widget.size - widget.margin,
                    pos.dy,
                  );
                });
              },
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF4F1FF), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x476356D9),
                      blurRadius: _dragging ? 24 : 16,
                      offset: Offset(0, _dragging ? 10 : 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, size: 26, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// Round avatar with online dot, used at the end of the tab headers.
class HeaderAvatar extends StatelessWidget {
  final TeamMember member;
  final VoidCallback? onTap;

  const HeaderAvatar({super.key, required this.member, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(210), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x242A2458),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: AvatarWidget.fromMember(member, radius: 22.5, fontSize: 12),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppTheme.green,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.surface, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
