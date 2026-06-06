import '../database/database_helper.dart';
import '../models/user_model.dart';

/// Repositório responsável pelas operações CRUD na tabela `users`.
///
/// TODAS as operações usam exclusivamente `execute()` e `rawQuery()` porque
/// os helpers do sqflite (`insert`, `query`, `update`, `delete`) passam pelo
/// bridge JS do sqflite_common_ffi_web e retornam `null` onde `int` é esperado,
/// causando "Unsupported operation: unsupported result null (null)".
class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertUser(UserModel user) async {
    final db = await _dbHelper.database;
    // Usa o helper padrão agora que o toMap() é seguro para JS FFI
    return await db.insert('users', user.toMap());
  }

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

  Future<bool> emailExists(String email) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  Future<UserModel?> getUserById(String id) async {
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
