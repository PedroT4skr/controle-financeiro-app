import '../database/database_helper.dart';
import '../models/transaction_model.dart';

/// Repositório responsável pelas operações CRUD na tabela `transactions`.
class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insere uma nova transação e retorna o id gerado.
  /// Usa rawInsert para evitar o bug do web FFI com ConflictAlgorithm.
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    final map = transaction.toMap();

    await db.rawInsert(
      'INSERT INTO transactions (user_id, title, amount, date, type) VALUES (?, ?, ?, ?, ?)',
      [map['user_id'], map['title'], map['amount'], map['date'], map['type']],
    );

    final result = await db.rawQuery('SELECT last_insert_rowid() as id');
    return (result.first['id'] as int?) ?? 0;
  }

  /// Atualiza uma transação existente. Retorna a quantidade de linhas afetadas.
  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    return db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  /// Exclui uma transação pelo id. Retorna a quantidade de linhas removidas.
  Future<int> deleteTransaction(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Lista todas as transações de um usuário, ordenadas por data decrescente.
  Future<List<TransactionModel>> getTransactionsByUser(int userId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return results.map((map) => TransactionModel.fromMap(map)).toList();
  }

  /// Calcula o saldo total: soma de receitas - soma de despesas.
  Future<double> getBalance(int userId) async {
    final db = await _dbHelper.database;

    final incomeResult = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE user_id = ? AND type = 'receita'",
      [userId],
    );

    final expenseResult = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE user_id = ? AND type = 'despesa'",
      [userId],
    );

    final income = (incomeResult.first['total'] as num).toDouble();
    final expense = (expenseResult.first['total'] as num).toDouble();

    return income - expense;
  }

  /// Retorna o total de receitas para um usuário.
  Future<double> getTotalIncome(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE user_id = ? AND type = 'receita'",
      [userId],
    );
    return (result.first['total'] as num).toDouble();
  }

  /// Retorna o total de despesas para um usuário.
  Future<double> getTotalExpenses(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE user_id = ? AND type = 'despesa'",
      [userId],
    );
    return (result.first['total'] as num).toDouble();
  }
}
