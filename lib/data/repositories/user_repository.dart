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

  /// Insere um novo usuário e retorna o id gerado.
  Future<int> insertUser(UserModel user) async {
    final db = await _dbHelper.database;

    // execute() retorna void — não depende do retorno do FFI bridge
    await db.execute(
      'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
      [user.name, user.email, user.password],
    );

    // Recupera o ID via SELECT — rawQuery retorna rows, não int
    final rows = await db.rawQuery('SELECT last_insert_rowid() as id');
    if (rows.isNotEmpty && rows.first['id'] != null) {
      return rows.first['id'] as int;
    }
    return 0;
  }

  /// Busca um usuário por email e senha (login).
  /// Retorna null se as credenciais forem inválidas.
  Future<UserModel?> authenticate(String email, String password) async {
    final db = await _dbHelper.database;

    final results = await db.rawQuery(
      'SELECT * FROM users WHERE email = ? AND password = ? LIMIT 1',
      [email, password],
    );

    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  /// Verifica se já existe um usuário com o email informado.
  Future<bool> emailExists(String email) async {
    final db = await _dbHelper.database;

    final results = await db.rawQuery(
      'SELECT id FROM users WHERE email = ? LIMIT 1',
      [email],
    );

    return results.isNotEmpty;
  }

  /// Busca um usuário pelo id.
  Future<UserModel?> getUserById(int id) async {
    final db = await _dbHelper.database;

    final results = await db.rawQuery(
      'SELECT * FROM users WHERE id = ? LIMIT 1',
      [id],
    );

    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }
}
