class TeamMember {
  final String id;
  final String name;
  final String firstName;
  final String initials;
  final String role;
  final String avatarColor;

  TeamMember({
    required this.id,
    required this.name,
    required this.firstName,
    required this.initials,
    required this.role,
    required this.avatarColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'first_name': firstName,
      'initials': initials,
      'role': role,
      'avatar_color': avatarColor,
    };
  }

  factory TeamMember.fromMap(Map<String, dynamic> map) {
    return TeamMember(
      id: map['id'],
      name: map['name'],
      firstName: map['first_name'],
      initials: map['initials'],
      role: map['role'],
      avatarColor: map['avatar_color'],
    );
  }

  TeamMember copyWith({
    String? id,
    String? name,
    String? firstName,
    String? initials,
    String? role,
    String? avatarColor,
  }) {
    return TeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      initials: initials ?? this.initials,
      role: role ?? this.role,
      avatarColor: avatarColor ?? this.avatarColor,
    );
  }
}
