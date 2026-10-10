import 'package:flutter/material.dart';
import '../models/team_member.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_widget.dart';
import 'main_shell.dart';

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  final TaskService _taskService = TaskService();
  
  List<TeamMember> _members = [];
  bool _isLoading = true;
  String? _errorMessage;
  TeamMember? _selectedMember;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await _taskService.getAllMembers();
      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onContinue() {
    if (_selectedMember != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainShell(currentUser: _selectedMember!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome Chrome Header
          Container(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 30, 24, 27),
            decoration: BoxDecoration(
              color: AppTheme.chrome,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
              border: Border(bottom: BorderSide(color: AppTheme.primary.withAlpha(31))), // 12% opacity
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'SLA Tracker',
                      style: TextStyle(
                        color: AppTheme.primaryDeep,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 35),
                const Text(
                  'WELCOME',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Who are you using the app as?',
                  style: TextStyle(
                    color: AppTheme.text,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.875, // -0.035em * 25
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Select your team profile to continue. This simply personalizes your task view—there’s no account or sign-in required.',
                  style: TextStyle(
                    color: Color(0xFF615E78),
                    fontSize: 11.5,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          // Scrollable Member Selection
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(21, 24, 21, 30),
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 2, right: 2, bottom: 10),
                  child: Text(
                    'Team members',
                    style: TextStyle(
                      color: AppTheme.textSoft,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isLoading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ))
                else if (_errorMessage != null)
                  Center(child: Text('Error: $_errorMessage'))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _members.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final isSelected = _selectedMember?.id == member.id;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMember = member;
                          });
                        },
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 67),
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Color.alphaBlend(AppTheme.primary.withAlpha(13), AppTheme.surface) // ~5% 
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppTheme.primary.withAlpha(92) : const Color(0x0F202030), // 36% vs 6%
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected 
                                    ? AppTheme.primary.withAlpha(20) // ~8% 
                                    : const Color(0x091D1D2F), // 3.5%
                                blurRadius: 18,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              AvatarWidget.fromMember(member, radius: 20), // Creates 40x40 avatar
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.name,
                                      style: const TextStyle(
                                        color: AppTheme.text,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      member.role,
                                      style: const TextStyle(
                                        color: AppTheme.textFaint,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primary : const Color(0xFFCFCED9),
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: isSelected 
                                    ? Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle))
                                    : null,
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 18),
                // Welcome Continue
                ElevatedButton(
                  onPressed: _selectedMember == null ? null : _onContinue,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero, // Removed to control inner layout precisely
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.primary.withAlpha(115), // manually scaling via opacity mix below
                    disabledForegroundColor: Colors.white.withAlpha(115),
                    shadowColor: AppTheme.primary.withAlpha(56), // 22%
                    elevation: _selectedMember == null ? 0 : 5,
                    minimumSize: const Size.fromHeight(47),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios, size: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                const Text(
                  'You can view other team members from the Team tab.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textFaint,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

