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

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),
      const TasksScreen(),
      const TeamScreen(),
      ProfileScreen(currentUser: widget.currentUser),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavItem(int index, IconData iconOutlined, IconData iconFilled, String label) {
    final isActive = _selectedIndex == index;
    final color = isActive ? AppTheme.primary : const Color(0xFF7F7A99);
    
    return Expanded(
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
              child: Icon(isActive ? iconFilled : iconOutlined, color: color, size: 21),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF4F1FF),
          border: Border(top: BorderSide(color: AppTheme.primary.withAlpha(31))),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Overview'),
              _buildNavItem(1, Icons.list_alt_outlined, Icons.list_alt, 'Tasks'),
              _buildNavItem(2, Icons.people_outline, Icons.people, 'Team'),
              _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

