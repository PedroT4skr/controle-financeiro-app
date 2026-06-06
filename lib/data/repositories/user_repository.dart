import '../database/database_helper.dart';
import '../models/user_model.dart';

/// Repositório responsável pelas operações CRUD na tabela `users`.
class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insere um novo usuário e retorna o id gerado.
  /// Usa rawInsert para evitar o bug do web FFI com ConflictAlgorithm.
  Future<int> insertUser(UserModel user) async {
    final db = await _dbHelper.database;
    final map = user.toMap();

    await db.rawInsert(
      'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
      [map['name'], map['email'], map['password']],
    );

    // Recupera o ID manualmente — o web FFI não retorna de forma confiável
    final result = await db.rawQuery('SELECT last_insert_rowid() as id');
    return (result.first['id'] as int?) ?? 0;
  }

  /// Busca um usuário por email e senha (login).
  /// Retorna null se as credenciais forem inválidas.
  Future<UserModel?> authenticate(String email, String password) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  /// Verifica se já existe um usuário com o email informado.
  Future<bool> emailExists(String email) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Busca um usuário pelo id.
  Future<UserModel?> getUserById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }
}
