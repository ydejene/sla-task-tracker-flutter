import '../models/team_member.dart';
import '../services/storage_service.dart';

/// Coordinates team-member data and the currently selected user.
///
/// Screens call these methods and then `setState()` to rebuild.
class TeamController {
  TeamController({StorageService? storage})
    : _storage = storage ?? StorageService.instance;

  final StorageService _storage;

  List<TeamMember> _members = [];
  TeamMember? _currentUser;

  List<TeamMember> get members => List.unmodifiable(_members);
  TeamMember? get currentUser => _currentUser;

  Future<void> loadMembers() async {
    _members = await _storage.getMembers();
    // Keep the session user in sync with freshly loaded data.
    if (_currentUser != null) _currentUser = getMember(_currentUser!.id);
  }

  TeamMember? getMember(String? id) {
    if (id == null) return null;
    for (final m in _members) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Stores the selected user for the current session (no authentication).
  void selectUser(TeamMember member) => _currentUser = member;

  void clearUser() => _currentUser = null;
}
