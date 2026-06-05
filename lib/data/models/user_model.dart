class UserModel {
  final int? id;
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
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }

  /// Serializa UserModel para Map (inserção no SQLite).
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'password': password,
    };
  }

  /// Cria uma cópia com campos opcionalmente substituídos.
  UserModel copyWith({
    int? id,
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
