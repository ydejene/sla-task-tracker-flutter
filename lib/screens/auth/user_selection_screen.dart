import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../models/team_member.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/common.dart';
import '../../widgets/member_avatar.dart';
import '../home_shell.dart';

/// Screen 1 — choose which team member is using the app (no real auth).
class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  bool _started = false;
  bool _loading = true;
  bool _continuing = false;
  String? _error;
  String? _selectedId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    final team = AppScope.of(context).team;
    try {
      await team.loadMembers();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _selectedId = team.currentUser?.id;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not open the local database.\n$e';
      });
    }
  }

  Future<void> _continue() async {
    final scope = AppScope.of(context);
    final member = scope.team.getMember(_selectedId);
    if (member == null) return;
    setState(() => _continuing = true);
    scope.team.selectUser(member);
    await scope.tasks.loadTasks();
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
  }

  @override
  Widget build(BuildContext context) {
    final members = AppScope.of(context).team.members;

    return Scaffold(
      body: Column(
        children: [
          ScreenHeader(child: _Intro()),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? EmptyState(
                    icon: Icons.storage_rounded,
                    title: 'Something went wrong',
                    message: _error!,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 2, bottom: 10),
                        child: Text(
                          'TEAM MEMBERS',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.9,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      for (final m in members)
                        _MemberOption(
                          member: m,
                          selected: m.id == _selectedId,
                          onTap: () => setState(() => _selectedId = m.id),
                        ),
                    ],
                  ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    loading: _continuing,
                    onPressed: _selectedId == null ? null : _continue,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'You can view other team members from the Team tab.',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              AppConstants.brandLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 34),
        const Text('WELCOME', style: AppText.eyebrow),
        const SizedBox(height: 8),
        const Text('Who are you using\nthe app as?', style: AppText.display),
        const SizedBox(height: 10),
        const Text(
          'Select your team profile to continue. This simply personalizes '
          'your task view—there’s no account or sign-in required.',
          style: TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: Color(0xFF615E78),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MemberOption extends StatelessWidget {
  const _MemberOption({
    required this.member,
    required this.selected,
    required this.onTap,
  });

  final TeamMember member;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFBFAFF) : Colors.white,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppShadows.card,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  MemberAvatar(member: member, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(member.role, style: AppText.caption),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : const Color(0xFFCFCED9),
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
