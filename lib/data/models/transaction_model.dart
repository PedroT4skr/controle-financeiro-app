/// Tipo de transação financeira.
enum TransactionType {
  receita, // income
  despesa, // expense
}

class TransactionModel {
  final int? id;
  final int userId;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;

  const TransactionModel({
    this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
  });

  /// Deserializa um Map (SQLite row) para TransactionModel.
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      type: map['type'] == 'receita'
          ? TransactionType.receita
          : TransactionType.despesa,
    );
  }

  /// Serializa TransactionModel para Map (inserção no SQLite).
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type == TransactionType.receita ? 'receita' : 'despesa',
    };
  }

  /// Cria uma cópia com campos opcionalmente substituídos.
  TransactionModel copyWith({
    int? id,
    int? userId,
    String? title,
    double? amount,
    DateTime? date,
    TransactionType? type,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
    );
  }

  /// Retorna label legível do tipo.
  String get typeLabel =>
      type == TransactionType.receita ? 'Receita' : 'Despesa';

  /// Retorna true se for receita.
  bool get isIncome => type == TransactionType.receita;

  @override
  String toString() =>
      'TransactionModel(id: $id, title: $title, amount: $amount, type: $typeLabel)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
