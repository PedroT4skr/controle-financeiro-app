import 'package:flutter/foundation.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/transaction_repository.dart';

/// ViewModel responsável pelo gerenciamento de transações financeiras.
/// Expõe listas reativas e agregações (saldo, receita total, despesa total).
class TransactionViewModel extends ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository();

  List<TransactionModel> _transactions = [];
  double _balance = 0.0;
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  bool _isLoading = false;
  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  double get balance => _balance;
  double get totalIncome => _totalIncome;
  double get totalExpenses => _totalExpenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ---------------------------------------------------------------------------
  // Carregar transações
  // ---------------------------------------------------------------------------

  /// Carrega todas as transações do usuário e recalcula os totais.
  Future<void> loadTransactions(int userId) async {
    _setLoading(true);
    _clearError();

    try {
      _transactions = await _repository.getTransactionsByUser(userId);
      _balance = await _repository.getBalance(userId);
      _totalIncome = await _repository.getTotalIncome(userId);
      _totalExpenses = await _repository.getTotalExpenses(userId);
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar transações: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Adicionar transação
  // ---------------------------------------------------------------------------

  /// Insere uma nova transação e recarrega os dados.
  Future<bool> addTransaction({
    required int userId,
    required String title,
    required double amount,
    required DateTime date,
    required TransactionType type,
  }) async {
    _clearError();

    try {
      final transaction = TransactionModel(
        userId: userId,
        title: title,
        amount: amount,
        date: date,
        type: type,
      );

      await _repository.insertTransaction(transaction);
      await loadTransactions(userId);
      return true;
    } catch (e) {
      _setError('Erro ao adicionar transação: ${e.toString()}');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Atualizar transação
  // ---------------------------------------------------------------------------

  /// Atualiza uma transação existente e recarrega os dados.
  Future<bool> updateTransaction({
    required int transactionId,
    required int userId,
    required String title,
    required double amount,
    required DateTime date,
    required TransactionType type,
  }) async {
    _clearError();

    try {
      final transaction = TransactionModel(
        id: transactionId,
        userId: userId,
        title: title,
        amount: amount,
        date: date,
        type: type,
      );

      await _repository.updateTransaction(transaction);
      await loadTransactions(userId);
      return true;
    } catch (e) {
      _setError('Erro ao atualizar transação: ${e.toString()}');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Excluir transação
  // ---------------------------------------------------------------------------

  /// Exclui uma transação pelo id e recarrega os dados.
  Future<bool> deleteTransaction(int transactionId, int userId) async {
    _clearError();

    try {
      await _repository.deleteTransaction(transactionId);
      await loadTransactions(userId);
      return true;
    } catch (e) {
      _setError('Erro ao excluir transação: ${e.toString()}');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers internos
  // ---------------------------------------------------------------------------

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
