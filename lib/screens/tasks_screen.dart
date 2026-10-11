import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/task_card.dart';
import 'task_details_screen.dart';
import 'task_form_screen.dart';

class TasksScreen extends StatefulWidget {
  final TeamMember currentUser;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onBack;

  const TasksScreen({
    super.key,
    required this.currentUser,
    this.onOpenProfile,
    this.onBack,
  });

  @override
  State<TasksScreen> createState() => TasksScreenState();
}

class TasksScreenState extends State<TasksScreen> {
  final TaskService _taskService = TaskService();
  final DatabaseService _dbService = DatabaseService();

  List<Task> _tasks = [];
  Map<String, TeamMember> _teamMembersMap = {};
  bool _isLoading = true;

  String _searchQuery = '';
  String _activeFilter = 'All';
  bool _showFilters = true;

  final List<String> _filters = [
    'All',
    'Todo',
    'In Progress',
    'Paused',
    'Completed',
    'At Risk',
    'Overdue',
  ];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      final tasks = await _taskService.getAllTasks();
      final members = await _dbService.getAllTeamMembers();
      final membersMap = {for (var m in members) m.id: m};

      if (mounted) {
        setState(() {
          _tasks = tasks;
          _teamMembersMap = membersMap;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    // Filter tasks based on search query and active filter
    final visibleTasks = _tasks.where((task) {
      final matchesQuery = task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesQuery) return false;

      if (_activeFilter == 'All') return true;

      // Status check
      if (task.status.value.toLowerCase() == _activeFilter.toLowerCase()) return true;

      // SLA check
      final sla = _taskService.computeSlaStatus(task);
      if (sla.value.toLowerCase() == _activeFilter.toLowerCase()) return true;

      return false;
    }).toList();

    final header = AppHeader(
      onBack: widget.onBack,
      actions: [
        HeaderAvatar(member: widget.currentUser, onTap: widget.onOpenProfile),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tasks',
            style: TextStyle(
              color: AppTheme.text,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.035 * 23,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_tasks.length} tasks across your team',
            style: const TextStyle(color: Color(0xFF5E5B78), fontSize: 12.5),
          ),
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.line),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search,
                                  size: 18,
                                  color: AppTheme.textFaint,
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: TextField(
                                    onChanged: (val) {
                                      setState(() {
                                        _searchQuery = val;
                                      });
                                    },
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.text,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Search tasks',
                                      hintStyle: TextStyle(
                                        color: Color(0xFFAAAAB6),
                                        fontSize: 12,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showFilters = !_showFilters;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 44,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _showFilters ? AppTheme.primary : AppTheme.primarySoft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x1F6356D9)),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.filter_list_rounded,
                              size: 18,
                              color: _showFilters ? Colors.white : AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showFilters) ...[
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filters.map((filter) {
                            final isSelected = _activeFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 7),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _activeFilter = filter;
                                  });
                                },
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.primary : AppTheme.surface,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: isSelected ? AppTheme.primary : AppTheme.line,
                                    ),
                                    boxShadow: isSelected
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x2E6356D9),
                                              blurRadius: 9,
                                              offset: Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    filter,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : AppTheme.textSoft,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: loadTasks,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
                padding: const EdgeInsets.fromLTRB(21, 18, 21, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Results Heading
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _activeFilter == 'All' ? 'All tasks' : _activeFilter,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.text,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primarySoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${visibleTasks.length}',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),

                    // Task List or Empty State
                    if (visibleTasks.isEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFFD7D6E0),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.search, size: 24, color: AppTheme.primary),
                            SizedBox(height: 8),
                            Text(
                              'No matching tasks',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSoft,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Try another search or filter.',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppTheme.textFaint,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: visibleTasks.map((task) {
                          final sla = _taskService.computeSlaStatus(task);
                          final assignee = task.assignedTo != null
                              ? _teamMembersMap[task.assignedTo]
                              : null;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TaskCard(
                              task: task,
                              slaStatus: sla,
                              assignee: assignee,
                              onTap: () async {
                                final changed = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TaskDetailsScreen(
                                      taskId: task.id,
                                      currentUser: widget.currentUser,
                                    ),
                                  ),
                                );
                                if (changed == true) {
                                  loadTasks();
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
          ),
        ),
        DraggableFab(
          onPressed: () async {
            final created = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => TaskFormScreen(currentUser: widget.currentUser),
              ),
            );
            if (created == true) {
              loadTasks();
            }
          },
        ),
      ],
    ),
    ),
    ],
  ),
  );
  }
}
