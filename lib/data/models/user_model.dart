class UserModel {
  final String? id;
  final String name;
  final String email;
  final String password;

  const UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  /// Deserializa um Map (SQLite row) para UserModel.
  factory UserModel.fromMap(Map<String, Object?> map) {
    return UserModel(
      id: map['id'] as String?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }

  /// Serializa UserModel para Map (inserção no SQLite).
  /// Usa Map<String, Object?> — tipo exato esperado pelo sqflite na web.
  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'name': name,
      'email': email,
      'password': password,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Cria uma cópia com campos opcionalmente substituídos.
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }

  @override
  String toString() => 'UserModel(id: $id, name: $name, email: $email)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}
