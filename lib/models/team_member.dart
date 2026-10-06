/// A member of the project team.
///
/// [avatar] stores the key of the avatar colour palette (see `MemberAvatar`).
class TeamMember {
  final String id;
  final String name;
  final String role;
  final String avatar;

  const TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.avatar,
  });

  String get firstName => name.split(' ').first;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'role': role,
    'avatar': avatar,
  };

  factory TeamMember.fromMap(Map<String, Object?> map) => TeamMember(
    id: map['id'] as String,
    name: map['name'] as String,
    role: map['role'] as String,
    avatar: map['avatar'] as String,
  );
}
