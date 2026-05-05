class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? fotoProfil;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.fotoProfil,
  });

  // foto profil
  factory User.fromJson(Map<String, dynamic> json) {
    String? foto = json['foto_profil']?.toString();
    if (foto == 'null' || foto == '') foto = null;

    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'] ?? 'user',
      fotoProfil: foto,
    );
  }

  User copyWith({String? name, String? fotoProfil}) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      fotoProfil: fotoProfil ?? this.fotoProfil,
    );
  }
}
