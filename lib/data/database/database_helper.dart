import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart' as p;

/// Singleton que gerencia a conexão com o banco SQLite.
/// Suporta Web (via sqflite_common_ffi_web) e plataformas nativas.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  /// Retorna a instância do banco, inicializando se necessário.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa o banco com a factory correta para cada plataforma.
  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // Usa o factory FFI Web para rodar no browser / Codespaces
      databaseFactory = databaseFactoryFfiWeb;
      return databaseFactory.openDatabase(
        'controle_financeiro.db',
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _onCreate,
        ),
      );
    }

    // Plataforma nativa (mobile/desktop)
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'controle_financeiro.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Cria as tabelas na primeira execução.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('receita', 'despesa')),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Índice para consultas por usuário — evita full table scan
    await db.execute(
      'CREATE INDEX idx_transactions_user ON transactions(user_id)',
    );
  }

  /// Fecha o banco (útil em testes e teardown).
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
