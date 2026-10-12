import 'package:flutter/material.dart';

import '../models/team_member.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'tasks_screen.dart';
import 'team_screen.dart';

class MainShell extends StatefulWidget {
  final TeamMember currentUser;

  const MainShell({super.key, required this.currentUser});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final GlobalKey<DashboardScreenState> _dashboardKey =
      GlobalKey<DashboardScreenState>();
  final GlobalKey<TasksScreenState> _tasksKey = GlobalKey<TasksScreenState>();
  final GlobalKey<TeamScreenState> _teamKey = GlobalKey<TeamScreenState>();
  final GlobalKey<ProfileScreenState> _profileKey =
      GlobalKey<ProfileScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(
        key: _dashboardKey,
        currentUser: widget.currentUser,
        onOpenProfile: () => _onItemTapped(3),
      ),
      TasksScreen(
        key: _tasksKey,
        currentUser: widget.currentUser,
        onOpenProfile: () => _onItemTapped(3),
        onBack: () => _onItemTapped(0),
      ),
      TeamScreen(
        key: _teamKey,
        currentUser: widget.currentUser,
        onOpenProfile: () => _onItemTapped(3),
        onBack: () => _onItemTapped(0),
      ),
      ProfileScreen(
        key: _profileKey,
        currentUser: widget.currentUser,
        onBack: () => _onItemTapped(0),
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      _dashboardKey.currentState?.loadDashboardData();
    } else if (index == 1) {
      _tasksKey.currentState?.loadTasks();
    } else if (index == 2) {
      _teamKey.currentState?.loadTeamData();
    } else if (index == 3) {
      _profileKey.currentState?.loadMemberTasks();
    }
  }

  Widget _buildNavItem(
    int index,
    IconData iconOutlined,
    IconData iconFilled,
    String label,
  ) {
    final isActive = _selectedIndex == index;
    final color = isActive ? AppTheme.primary : const Color(0xFF7F7A99);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: '$label tab',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onItemTapped(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 31,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.chromeStrong : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isActive ? iconFilled : iconOutlined,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // System/gesture back on Tasks, Team or Profile returns to Overview first.
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onItemTapped(0);
      },
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: _screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F1FF),
            border: Border(
              top: BorderSide(color: AppTheme.primary.withAlpha(31)),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: SizedBox(
            height: 76,
            child: Row(
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Overview'),
                _buildNavItem(
                  1,
                  Icons.list_alt_outlined,
                  Icons.list_alt,
                  'Tasks',
                ),
                _buildNavItem(2, Icons.people_outline, Icons.people, 'Team'),
                _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
