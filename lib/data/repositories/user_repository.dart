import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

/// Repositório responsável pelas operações CRUD na tabela `users`.
class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insere um novo usuário e retorna o id gerado.
  Future<int> insertUser(UserModel user) async {
    final db = await _dbHelper.database;
    return db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
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
