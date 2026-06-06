import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../data/models/transaction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/market_provider.dart';
import 'login_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.read(transactionProvider.notifier).loadTransactions(user.id!);
      }
    });
  }

  void _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final txState = ref.watch(transactionProvider);
    final marketState = ref.watch(marketProvider);
    
    final user = authState.user;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(theme, user.name),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _BalanceCard(
                balance: txState.balance,
                income: txState.totalIncome,
                expenses: txState.totalExpenses,
                isLoading: txState.isLoading,
              ),
            ),
          ),
          
          // Seção Market Trends (API Externa)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Radar Financeiro (Trending)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildMarketTrends(marketState, theme),
          ),

          // Seção Transações
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transações Recentes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Lista de Transações com Shimmer
          if (txState.isLoading && txState.transactions.isEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const _TransactionShimmer(),
                childCount: 4,
              ),
            )
          else if (txState.transactions.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: theme.colorScheme.surfaceContainerHighest),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma transação ainda.',
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tx = txState.transactions[index];
                  return _TransactionListItem(
                    transaction: tx,
                    onDelete: () => ref.read(transactionProvider.notifier).deleteTransaction(tx.id!, user.id!),
                  );
                },
                childCount: txState.transactions.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionModal(context, user.id!),
        icon: const Icon(Icons.add),
        label: const Text('Nova'),
      ),
    );
  }

  Widget _buildMarketTrends(MarketState marketState, ThemeData theme) {
    if (marketState.isLoading) {
      return SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (context, _) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[800]!,
              highlightColor: Colors.grey[700]!,
              child: Container(
                width: 140,
                height: 100,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      );
    }

    if (marketState.errorMessage != null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Erro ao carregar mercado'))),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: marketState.trendingCoins.length,
        itemBuilder: (context, index) {
          final coin = marketState.trendingCoins[index];
          return Card(
            margin: const EdgeInsets.only(right: 12),
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Image.network(coin.thumbUrl, width: 24, height: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          coin.symbol,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '${coin.priceBtc.toStringAsFixed(6)} BTC',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(ThemeData theme, String userName) {
    final firstName = userName.split(' ').first;
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              firstName[0].toUpperCase(),
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Olá, $firstName', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text('Bem-vindo de volta', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout,
        ),
      ],
    );
  }

  void _showAddTransactionModal(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _TransactionForm(userId: userId),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expenses;
  final bool isLoading;

  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expenses,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[800]!,
        highlightColor: Colors.grey[700]!,
        child: Container(
          height: 180,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F2027),
            Color(0xFF203A43),
            Color(0xFF2C5364),
          ],
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Saldo Total', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(currencyFormatter.format(balance), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('Receitas', income, Icons.arrow_downward, Colors.greenAccent),
              _buildMiniStat('Despesas', expenses, Icons.arrow_upward, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, double amount, IconData icon, Color color) {
    final currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(currencyFormatter.format(amount), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

class _TransactionShimmer extends StatelessWidget {
  const _TransactionShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[800]!,
        highlightColor: Colors.grey[700]!,
        child: Row(
          children: [
            Container(width: 50, height: 50, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: double.infinity, height: 16, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 100, height: 14, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionListItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onDelete;

  const _TransactionListItem({required this.transaction, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.receita;
    final color = isIncome ? Colors.green : Colors.red;
    final icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;
    final currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Dismissible(
      key: Key(transaction.id ?? transaction.hashCode.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(transaction.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('dd/MM/yyyy').format(transaction.date)),
        trailing: Text(
          '${isIncome ? '+' : '-'} ${currencyFormatter.format(transaction.amount)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}

// O restante do formulário e etc pode ser um stateful widget que consome ref.read
class _TransactionForm extends ConsumerStatefulWidget {
  final String userId;
  const _TransactionForm({required this.userId});

  @override
  ConsumerState<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<_TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  TransactionType _type = TransactionType.despesa;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nova Transação', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(value: TransactionType.despesa, label: Text('Despesa')),
                ButtonSegment(value: TransactionType.receita, label: Text('Receita')),
              ],
              selected: {_type},
              onSelectionChanged: (set) => setState(() => _type = set.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (v) => v!.isEmpty ? 'Informe um título' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Valor'),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Informe o valor' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final amount = double.parse(_amountController.text.replaceAll(',', '.'));
                  await ref.read(transactionProvider.notifier).addTransaction(
                    userId: widget.userId,
                    title: _titleController.text,
                    amount: amount,
                    date: DateTime.now(),
                    type: _type,
                  );
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
