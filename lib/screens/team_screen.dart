import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/team_member_card.dart';
import 'profile_screen.dart';

/// Team tab: every member with their open task count.
/// Tapping a member opens their profile.
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key, this.currentUser});

  /// Used for the "You" badge and the header avatar.
  final TeamMember? currentUser;

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final TaskService _taskService = TaskService();

  bool _isLoading = true;
  List<TeamMember> _members = [];
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  Future<void> _loadTeam() async {
    try {
      final members = await _taskService.getAllMembers();
      final tasks = await _taskService.getAllTasks();
      if (!mounted) return;
      setState(() {
        _members = members;
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load team: $e')));
    }
  }

  int _openTasksFor(TeamMember member) => _tasks
      .where(
        (t) => t.assignedTo == member.id && t.status != TaskStatus.completed,
      )
      .length;

  Future<void> _openMember(TeamMember member) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          currentUser: widget.currentUser ?? member,
          memberToView: member,
        ),
      ),
    );
    // Tasks may have changed while viewing the profile.
    _loadTeam();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: _loadTeam,
        color: AppTheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(21, 24, 21, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text(
                    'Team members',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.32,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'View ownership and current task load',
                    style: TextStyle(fontSize: 11.5, color: AppTheme.textFaint),
                  ),
                  const SizedBox(height: 13),
                  if (_members.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No team members found.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textFaint,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._members.map(
                      (m) => TeamMemberCard(
                        member: m,
                        openTasks: _openTasksFor(m),
                        isCurrentUser: m.id == widget.currentUser?.id,
                        onTap: () => _openMember(m),
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
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
                    'Team',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_members.length} ${_members.length == 1 ? 'person' : 'people'} on your delivery team',
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
