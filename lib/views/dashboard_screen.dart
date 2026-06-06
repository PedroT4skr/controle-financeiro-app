import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../data/models/transaction_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/transaction_viewmodel.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Carrega as transações ao entrar no Dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null) {
        context.read<TransactionViewModel>().loadTransactions(user.id!);
      }
    });
  }

  /// Formata moeda em Real brasileiro.
  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatter.format(value);
  }

  /// Formata data para exibição.
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Abre o BottomSheet para adicionar ou editar uma transação.
  void _showTransactionSheet({TransactionModel? transaction}) {
    final isEditing = transaction != null;
    final titleController =
        TextEditingController(text: isEditing ? transaction.title : '');
    final amountController = TextEditingController(
      text: isEditing ? transaction.amount.toStringAsFixed(2) : '',
    );
    var selectedType =
        isEditing ? transaction.type : TransactionType.receita;
    var selectedDate = isEditing ? transaction.date : DateTime.now();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Título do sheet
                    Text(
                      isEditing ? 'Editar Transação' : 'Nova Transação',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Título da transação
                    TextFormField(
                      controller: titleController,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Insira um título'
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Título',
                        hintText: 'Ex: Salário, Aluguel...',
                        prefixIcon: const Icon(Icons.description_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Valor
                    TextFormField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Insira o valor';
                        }
                        final parsed =
                            double.tryParse(v.replaceAll(',', '.'));
                        if (parsed == null || parsed <= 0) {
                          return 'Insira um valor válido maior que zero';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Valor (R\$)',
                        hintText: '0.00',
                        prefixIcon:
                            const Icon(Icons.attach_money_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tipo (Receita / Despesa)
                    Row(
                      children: [
                        Expanded(
                          child: _TypeChip(
                            label: 'Receita',
                            icon: Icons.trending_up_rounded,
                            color: const Color(0xFF2E7D32),
                            isSelected:
                                selectedType == TransactionType.receita,
                            onTap: () {
                              setSheetState(() {
                                selectedType = TransactionType.receita;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TypeChip(
                            label: 'Despesa',
                            icon: Icons.trending_down_rounded,
                            color: const Color(0xFFC62828),
                            isSelected:
                                selectedType == TransactionType.despesa,
                            onTap: () {
                              setSheetState(() {
                                selectedType = TransactionType.despesa;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Seletor de Data
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setSheetState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Data',
                          prefixIcon:
                              const Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(_formatDate(selectedDate)),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Botão Salvar
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          final user =
                              context.read<AuthViewModel>().currentUser;
                          if (user == null) return;

                          final txVM =
                              context.read<TransactionViewModel>();
                          final amount = double.parse(
                            amountController.text.replaceAll(',', '.'),
                          );

                          bool success;
                          if (isEditing) {
                            success = await txVM.updateTransaction(
                              transactionId: transaction.id!,
                              userId: user.id!,
                              title: titleController.text.trim(),
                              amount: amount,
                              date: selectedDate,
                              type: selectedType,
                            );
                          } else {
                            success = await txVM.addTransaction(
                              userId: user.id!,
                              title: titleController.text.trim(),
                              amount: amount,
                              date: selectedDate,
                              type: selectedType,
                            );
                          }

                          if (success && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: Icon(
                            isEditing ? Icons.save_rounded : Icons.add_rounded),
                        label: Text(
                          isEditing ? 'Salvar Alterações' : 'Adicionar',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Diálogo de confirmação para exclusão.
  void _showDeleteDialog(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Icon(
            Icons.delete_forever_rounded,
            color: theme.colorScheme.error,
            size: 40,
          ),
          title: const Text('Excluir Transação'),
          content: Text(
            'Tem certeza que deseja excluir "${transaction.title}"?\nEssa ação não pode ser desfeita.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final user = context.read<AuthViewModel>().currentUser;
                if (user == null) return;

                await context
                    .read<TransactionViewModel>()
                    .deleteTransaction(transaction.id!, user.id!);

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  void _handleLogout() {
    context.read<AuthViewModel>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authVM = context.watch<AuthViewModel>();
    final txVM = context.watch<TransactionViewModel>();
    final user = authVM.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Olá, ${user?.name ?? 'Usuário'}!',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sair',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (user != null) {
            await txVM.loadTransactions(user.id!);
          }
        },
        child: CustomScrollView(
          slivers: [
            // ---------------------------------------------------------------
            // Cards de Resumo Financeiro
            // ---------------------------------------------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _BalanceCard(
                  balance: txVM.balance,
                  income: txVM.totalIncome,
                  expenses: txVM.totalExpenses,
                  formatCurrency: _formatCurrency,
                ),
              ),
            ),

            // ---------------------------------------------------------------
            // Título da lista
            // ---------------------------------------------------------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transações',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${txVM.transactions.length} registros',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---------------------------------------------------------------
            // Lista de Transações
            // ---------------------------------------------------------------
            if (txVM.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (txVM.transactions.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 80,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma transação encontrada',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toque no + para adicionar sua primeira transação',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: txVM.transactions.length,
                  itemBuilder: (context, index) {
                    final tx = txVM.transactions[index];
                    final isIncome = tx.isIncome;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant
                                .withOpacity(0.5),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isIncome
                                  ? const Color(0xFF2E7D32).withOpacity(0.12)
                                  : const Color(0xFFC62828).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isIncome
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              color: isIncome
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFC62828),
                            ),
                          ),
                          title: Text(
                            tx.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            _formatDate(tx.date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${isIncome ? '+' : '-'} ${_formatCurrency(tx.amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isIncome
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFC62828),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert_rounded,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showTransactionSheet(transaction: tx);
                                  } else if (value == 'delete') {
                                    _showDeleteDialog(tx);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 20),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outlined,
                                            size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Excluir',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Espaçamento no final
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTransactionSheet(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nova Transação',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// =============================================================================
// Widget: Card de Saldo
// =============================================================================

class _BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expenses;
  final String Function(double) formatCurrency;

  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expenses,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shadowColor: theme.colorScheme.primary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8),
              theme.colorScheme.tertiary,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo Total',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatCurrency(balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),

              // Receitas e Despesas
              Row(
                children: [
                  Expanded(
                    child: _SummaryItem(
                      icon: Icons.trending_up_rounded,
                      label: 'Receitas',
                      value: formatCurrency(income),
                      iconColor: const Color(0xFF81C784),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  Expanded(
                    child: _SummaryItem(
                      icon: Icons.trending_down_rounded,
                      label: 'Despesas',
                      value: formatCurrency(expenses),
                      iconColor: const Color(0xFFEF9A9A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Widget: Item de Resumo (Receita/Despesa)
// =============================================================================

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Widget: Chip de seleção de tipo (Receita/Despesa)
// =============================================================================

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? color
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? color
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
