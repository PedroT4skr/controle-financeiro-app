import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

/// Estado das transações (suporta UI com Shimmer)
class TransactionState {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String? errorMessage;
  
  final double balance;
  final double totalIncome;
  final double totalExpenses;

  TransactionState({
    this.transactions = const [],
    this.isLoading = true, // Começa em true para Shimmer
    this.errorMessage,
    this.balance = 0.0,
    this.totalIncome = 0.0,
    this.totalExpenses = 0.0,
  });

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    bool? isLoading,
    String? errorMessage,
    double? balance,
    double? totalIncome,
    double? totalExpenses,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      balance: balance ?? this.balance,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
    );
  }
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  final TransactionRepository _repo;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TransactionNotifier(this._repo) : super(TransactionState());

  /// Carrega do SQLite primeiro (rápido), depois tenta atualizar do Firestore no background
  Future<void> loadTransactions(String userId) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // 1. Prioridade Offline: Carrega do SQLite
      await _refreshLocalData(userId);

      // 2. Tenta sincronizar com o Firebase em background (se houver internet)
      final connectivityResult = await Connectivity().checkConnectivity();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        _syncFromFirestore(userId);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Erro ao carregar offline: $e');
    }
  }

  Future<void> _refreshLocalData(String userId) async {
    final txs = await _repo.getTransactionsByUser(userId);
    final balance = await _repo.getTotalBalance(userId);
    final income = await _repo.getTotalIncome(userId);
    final expenses = await _repo.getTotalExpenses(userId);

    state = state.copyWith(
      transactions: txs,
      balance: balance,
      totalIncome: income,
      totalExpenses: expenses,
      isLoading: false,
    );
  }

  Future<void> _syncFromFirestore(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .get();
          
      // Na prática real, aqui compararíamos timestamps.
      // Para fins do projeto, garantimos que todas do firestore estão no local
      for (var doc in snapshot.docs) {
        final tx = TransactionModel.fromMap(doc.data());
        // Insert usa db.insert que lida com o ignore se já existir
        await _repo.insertTransaction(tx);
      }
      await _refreshLocalData(userId);
    } catch (e) {
      print('Erro ao sincronizar do Firestore: $e');
    }
  }

  Future<bool> addTransaction({
    required String userId,
    required String title,
    required double amount,
    required DateTime date,
    required TransactionType type,
    required String category,
    required String paymentMethod,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final newTx = TransactionModel(
        userId: userId,
        title: title,
        amount: amount,
        date: date,
        type: type,
        category: category,
        paymentMethod: paymentMethod,
      );

      // 1. Salva no SQLite (Rápido e garantido)
      await _repo.insertTransaction(newTx);
      
      // 2. Atualiza a UI imediatamente (Offline-first)
      await _refreshLocalData(userId);
      
      // 3. Salva no Firebase em background (não trava a tela se houver erro ou AdBlock)
      _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(newTx.id)
          .set(newTx.toMap())
          .catchError((e) => print('Aviso de sync Firebase (Add): $e'));

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateTransaction({
    required String transactionId,
    required String userId,
    required String title,
    required double amount,
    required DateTime date,
    required TransactionType type,
    required String category,
    required String paymentMethod,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final updatedTx = TransactionModel(
        id: transactionId,
        userId: userId,
        title: title,
        amount: amount,
        date: date,
        type: type,
        category: category,
        paymentMethod: paymentMethod,
      );

      // SQLite
      await _repo.updateTransaction(updatedTx);
      await _refreshLocalData(userId);
      
      // Firebase (Background)
      _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transactionId)
          .update(updatedTx.toMap())
          .catchError((e) => print('Aviso de sync Firebase (Update): $e'));

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteTransaction(String transactionId, String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      // SQLite
      await _repo.deleteTransaction(transactionId);
      await _refreshLocalData(userId);
      
      // Firebase (Background)
      _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transactionId)
          .delete()
          .catchError((e) => print('Aviso de sync Firebase (Delete): $e'));

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final transactionProvider = StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return TransactionNotifier(repo);
});
