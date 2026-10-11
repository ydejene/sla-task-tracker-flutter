import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/task_card.dart';
import 'task_details_screen.dart';
import 'task_form_screen.dart';

/// Filter chips on the Tasks screen. The first four match the task status,
/// At Risk and Overdue match the calculated SLA status.
enum _TaskFilter {
  all('All'),
  todo('Todo'),
  inProgress('In Progress'),
  paused('Paused'),
  completed('Completed'),
  atRisk('At Risk'),
  overdue('Overdue');

  final String label;
  const _TaskFilter(this.label);
}

/// Tasks tab: every task with search and filter chips.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, this.currentUser});

  /// Used for the header avatar.
  final TeamMember? currentUser;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TaskService _taskService = TaskService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<Task> _tasks = [];
  Map<String, TeamMember> _membersById = {};
  _TaskFilter _filter = _TaskFilter.all;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _taskService.getAllTasks();
      final members = await _taskService.getAllMembers();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _membersById = {for (final m in members) m.id: m};
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load tasks: $e')));
    }
  }

  // SLA status is always calculated from the task, never stored.
  SlaStatus _slaOf(Task task) =>
      _taskService.getSlaStatus(task, now: DateTime.now());

  bool _matchesFilter(Task task) {
    switch (_filter) {
      case _TaskFilter.all:
        return true;
      case _TaskFilter.todo:
        return task.status == TaskStatus.todo;
      case _TaskFilter.inProgress:
        return task.status == TaskStatus.inProgress;
      case _TaskFilter.paused:
        return task.status == TaskStatus.paused;
      case _TaskFilter.completed:
        return task.status == TaskStatus.completed;
      case _TaskFilter.atRisk:
        return _slaOf(task) == SlaStatus.atRisk;
      case _TaskFilter.overdue:
        return _slaOf(task) == SlaStatus.overdue;
    }
  }

  /// Search matches the title, description or assignee name.
  bool _matchesSearch(Task task) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    final assignee = _membersById[task.assignedTo]?.name.toLowerCase() ?? '';
    return task.title.toLowerCase().contains(query) ||
        task.description.toLowerCase().contains(query) ||
        assignee.contains(query);
  }

  Future<void> _openTask(Task task) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TaskDetailsScreen(taskId: task.id)),
    );
    if (changed == true) _loadTasks();
  }

  Future<void> _createTask() async {
    final created = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const TaskFormScreen()));
    if (created == true) _loadTasks();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() => _filter = _TaskFilter.all);
  }

  @override
  Widget build(BuildContext context) {
    final visible =
        _tasks.where((t) => _matchesFilter(t) && _matchesSearch(t)).toList()
          ..sort((a, b) => a.deadline.compareTo(b.deadline));
    final isFiltered =
        _filter != _TaskFilter.all || _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _createTask,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        tooltip: 'New task',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(21, 18, 21, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.text),
              decoration: InputDecoration(
                hintText: 'Search tasks or people',
                hintStyle: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textFaint,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: AppTheme.textFaint,
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () =>
                            setState(() => _searchController.clear()),
                      ),
                filled: true,
                fillColor: AppTheme.surface,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(21, 12, 21, 6),
              itemCount: _TaskFilter.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final filter = _TaskFilter.values[index];
                return _FilterChip(
                  label: filter.label,
                  selected: filter == _filter,
                  onTap: () => setState(() => _filter = filter),
                );
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadTasks,
                    color: AppTheme.primary,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(21, 14, 21, 96),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _filter == _TaskFilter.all
                                    ? 'All tasks'
                                    : '${_filter.label} tasks',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.text,
                                ),
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 22),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primarySoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${visible.length}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (visible.isEmpty)
                          _EmptyState(
                            filtered: isFiltered,
                            onClear: _clearFilters,
                          )
                        else
                          ...visible.map(
                            (t) => TaskCard(
                              task: t,
                              slaStatus: _slaOf(t),
                              assignee: _membersById[t.assignedTo],
                              onTap: () => _openTask(t),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = widget.currentUser;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(31),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: const EdgeInsets.only(bottom: 1),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          21,
          MediaQuery.of(context).padding.top + 22,
          21,
          20,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.chrome,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tasks',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_tasks.length} ${_tasks.length == 1 ? 'task' : 'tasks'} across your team',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5E5B78),
                    ),
                  ),
                ],
              ),
            ),
            if (user != null)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withAlpha(209),
                    width: 3,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x232A2458),
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: AvatarWidget.fromMember(user, radius: 20, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.primary : AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: selected ? AppTheme.primary : AppTheme.line),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textSoft,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered, required this.onClear});

  final bool filtered;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 26, color: AppTheme.textFaint),
          const SizedBox(height: 8),
          const Text(
            'No tasks found',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            filtered
                ? 'Try a different search or filter.'
                : 'Tap + to create the first task.',
            style: const TextStyle(fontSize: 11.5, color: AppTheme.textFaint),
          ),
          if (filtered)
            TextButton(onPressed: onClear, child: const Text('Clear filters')),
        ],
      ),
    );
  }
}
