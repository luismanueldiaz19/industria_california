class Role {
  final int id;
  final String name;
  final String guardName;
  final String? description;
  final int usersCount;

  Role({
    required this.id,
    required this.name,
    required this.guardName,
    this.description,
    this.usersCount = 0,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      name: json['name'],
      guardName: json['guard_name'] ?? 'web',
      description: json['description'],
      usersCount: json['users_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'guard_name': guardName,
      'description': description,
      'users_count': usersCount,
    };
  }
}
