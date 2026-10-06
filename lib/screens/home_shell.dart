import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../controllers/task_controller.dart';
import '../theme/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'navigation.dart';
import 'tasks/task_list_view.dart';
import 'team/profile_screen.dart';
import 'team/team_screen.dart';

/// Hosts the four main tabs and the bottom navigation bar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  /// Lifted up so the Dashboard can open the Task List pre-filtered.
  TaskFilter _taskFilter = TaskFilter.all;

  void _selectTab(int i) => setState(() => _index = i);

  void _openTasks(TaskFilter filter) {
    setState(() {
      _taskFilter = filter;
      _index = 1;
    });
  }

  Future<void> _createTask() async {
    final created = await AppNavigation.createTask(context);
    if (!mounted) return;
    setState(() {});
    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task "${created.title}" created')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Touch the scope so the shell rebuilds if controllers change.
    AppScope.of(context);

    final pages = [
      DashboardScreen(
        onOpenTasks: _openTasks,
        onOpenProfile: () => _selectTab(3),
        onChanged: () => setState(() {}),
      ),
      TaskListView(
        filter: _taskFilter,
        onFilterChanged: (f) => setState(() => _taskFilter = f),
        onChanged: () => setState(() {}),
        onOpenProfile: () => _selectTab(3),
      ),
      TeamScreen(
        onChanged: () => setState(() {}),
        onOpenProfile: () => _selectTab(3),
      ),
      ProfileScreen(onChanged: () => setState(() {})),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: _index <= 1 ? _CreateFab(onTap: _createTask) : null,
      bottomNavigationBar: _BottomNav(index: _index, onTap: _selectTab),
    );
  }
}

class _CreateFab extends StatelessWidget {
  const _CreateFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Create task',
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.navBg, width: 3),
          boxShadow: AppShadows.primary,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.grid_view_rounded, 'Overview'),
    (Icons.checklist_rounded, 'Tasks'),
    (Icons.groups_outlined, 'Team'),
    (Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBg,
        border: Border(top: BorderSide(color: Color(0x1F6356D9))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: _items[i].$1,
                    label: _items[i].$2,
                    active: i == index,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.navInactive;
    return Semantics(
      selected: active,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 32,
              decoration: BoxDecoration(
                color: active ? AppColors.navActive : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 23, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
