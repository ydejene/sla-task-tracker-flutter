import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../services/database_service.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/team_member_card.dart';
import 'profile_screen.dart';

class TeamScreen extends StatefulWidget {
  final TeamMember currentUser;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onBack;

  const TeamScreen({
    super.key,
    required this.currentUser,
    this.onOpenProfile,
    this.onBack,
  });

  @override
  State<TeamScreen> createState() => TeamScreenState();
}

class TeamScreenState extends State<TeamScreen> {
  final TaskService _taskService = TaskService();
  final DatabaseService _dbService = DatabaseService();

  List<TeamMember> _members = [];
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTeamData();
  }

  Future<void> loadTeamData() async {
    try {
      final members = await _dbService.getAllTeamMembers();
      final tasks = await _taskService.getAllTasks();

      if (mounted) {
        setState(() {
          _members = members;
          _tasks = tasks;
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeader(
            onBack: widget.onBack,
            actions: [
              HeaderAvatar(member: widget.currentUser, onTap: widget.onOpenProfile),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Team',
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
                  '${_members.length} team ${_members.length == 1 ? 'member' : 'members'}',
                  style: const TextStyle(color: Color(0xFF5E5B78), fontSize: 12.5),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: loadTeamData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: 
              // Team Members List
              Padding(
                padding: const EdgeInsets.fromLTRB(21, 18, 21, 24),
                child: Column(
                  children: _members.map((member) {
                    final assignedCount = _tasks
                        .where((t) => t.assignedTo == member.id && t.status != TaskStatus.completed)
                        .length;
                    final isCurrent = member.id == widget.currentUser.id;

                    return TeamMemberCard(
                      member: member,
                      isCurrentUser: isCurrent,
                      assignedCount: assignedCount,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(
                              currentUser: widget.currentUser,
                              memberToView: isCurrent ? null : member,
                            ),
                          ),
                        );
                        loadTeamData();
                      },
                    );
                  }).toList(),
                ),
              ),
        ),
      ),
    ),
        ],
      ),
    );
  }
}
