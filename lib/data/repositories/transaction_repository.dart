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

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(int id) async {
    final db = await _dbHelper.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

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

  Future<double> getBalance(int userId) async {
    final income = await getTotalIncome(userId);
    final expense = await getTotalExpenses(userId);
    return income - expense;
  }

  Future<double> getTotalIncome(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE user_id = ? AND type = 'receita'",
      [userId],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getTotalExpenses(int userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE user_id = ? AND type = 'despesa'",
      [userId],
    );
    return (result.first['total'] as num).toDouble();
  }
}
