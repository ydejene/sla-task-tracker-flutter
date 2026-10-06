import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../controllers/task_controller.dart';
import '../../models/task.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/task_card.dart';
import '../navigation.dart';

/// Screen 3 — main task-management view with search, filters and sorting.
class TaskListView extends StatefulWidget {
  const TaskListView({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    required this.onChanged,
    required this.onOpenProfile,
  });

  final TaskFilter filter;
  final ValueChanged<TaskFilter> onFilterChanged;
  final VoidCallback onChanged;
  final VoidCallback onOpenProfile;

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  final _search = TextEditingController();
  TaskSort _sort = TaskSort.deadline;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openTask(Task task) async {
    await AppNavigation.openTask(context, task.id);
    if (!mounted) return;
    setState(() {});
    widget.onChanged();
  }

  Future<void> _pickSort() async {
    final picked = await showModalBottomSheet<TaskSort>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Sort tasks by', style: AppText.sectionTitle),
              ),
              RadioGroup<TaskSort>(
                groupValue: _sort,
                onChanged: (v) => Navigator.pop(context, v),
                child: Column(
                  children: [
                    for (final s in TaskSort.values)
                      RadioListTile<TaskSort>(
                        value: s,
                        title: Text(s.label),
                        activeColor: AppColors.primary,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _sort = picked);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final controller = scope.tasks;
    final list = controller.filtered(
      filter: widget.filter,
      query: _search.text,
      sort: _sort,
      assigneeName: (t) => scope.team.getMember(t.assignedTo)?.name,
    );
    final hasQuery = _search.text.trim().isNotEmpty;

    return Column(
      children: [
        ScreenHeader(
          title: 'Tasks',
          subtitle:
              '${Formatters.plural(controller.tasks.length, 'task')} across your team',
          trailing: GestureDetector(
            onTap: widget.onOpenProfile,
            child: MemberAvatar(
              member: scope.team.currentUser,
              size: 50,
              ring: true,
              online: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Search tasks or people',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13.5,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                    ),
                    suffixIcon: hasQuery
                        ? IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => setState(_search.clear),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: 'Sort: ${_sort.label}',
                child: Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: _pickSort,
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.sort_rounded, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 58,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            itemCount: TaskFilter.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 7),
            itemBuilder: (context, i) {
              final f = TaskFilter.values[i];
              return _FilterChip(
                label: f.label,
                selected: f == widget.filter,
                onTap: () => widget.onFilterChanged(f),
              );
            },
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.filter == TaskFilter.all
                            ? 'All tasks'
                            : '${widget.filter.label} tasks',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    CountPill(label: '${list.length}'),
                  ],
                ),
              ),
              if (list.isEmpty)
                EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No tasks found',
                  message: hasQuery || widget.filter != TaskFilter.all
                      ? 'Try a different search or filter.'
                      : 'Create your first task with the + button.',
                  action: hasQuery || widget.filter != TaskFilter.all
                      ? TextButton(
                          onPressed: () {
                            _search.clear();
                            widget.onFilterChanged(TaskFilter.all);
                            setState(() {});
                          },
                          child: const Text('Clear filters'),
                        )
                      : null,
                )
              else
                for (final t in list)
                  TaskCard(
                    task: t,
                    sla: controller.slaOf(t),
                    assignee: scope.team.getMember(t.assignedTo),
                    onTap: () => _openTask(t),
                  ),
            ],
          ),
        ),
      ],
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
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x2E6356D9),
                    blurRadius: 9,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
