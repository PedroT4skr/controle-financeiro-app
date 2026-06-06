import '../database/database_helper.dart';
import '../models/transaction_model.dart';

/// Repositório responsável pelas operações CRUD na tabela `transactions`.
///
/// TODAS as operações usam exclusivamente `execute()` e `rawQuery()` porque
/// os helpers do sqflite (`insert`, `query`, `update`, `delete`) passam pelo
/// bridge JS do sqflite_common_ffi_web e retornam `null` onde `int` é esperado,
/// causando "Unsupported operation: unsupported result null (null)".
class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insere uma nova transação e retorna o id gerado.
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;

    await db.execute(
      'INSERT INTO transactions (user_id, title, amount, date, type) VALUES (?, ?, ?, ?, ?)',
      [
        transaction.userId,
        transaction.title,
        transaction.amount,
        transaction.date.toIso8601String(),
        transaction.type == TransactionType.receita ? 'receita' : 'despesa',
      ],
    );

    final rows = await db.rawQuery('SELECT last_insert_rowid() as id');
    if (rows.isNotEmpty && rows.first['id'] != null) {
      return rows.first['id'] as int;
    }
    return 0;
  }

  /// Atualiza uma transação existente.
  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;

    await db.execute(
      'UPDATE transactions SET title = ?, amount = ?, date = ?, type = ? WHERE id = ?',
      [
        transaction.title,
        transaction.amount,
        transaction.date.toIso8601String(),
        transaction.type == TransactionType.receita ? 'receita' : 'despesa',
        transaction.id,
      ],
    );
  }

  /// Exclui uma transação pelo id.
  Future<void> deleteTransaction(int id) async {
    final db = await _dbHelper.database;
    await db.execute('DELETE FROM transactions WHERE id = ?', [id]);
  }

  /// Lista todas as transações de um usuário, ordenadas por data decrescente.
  Future<List<TransactionModel>> getTransactionsByUser(int userId) async {
    final db = await _dbHelper.database;

    final results = await db.rawQuery(
      'SELECT * FROM transactions WHERE user_id = ? ORDER BY date DESC',
      [userId],
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
