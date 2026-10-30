// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/view_state.dart';
import '../models/transaction_model.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/empty_widget.dart';
import 'api_list_screen.dart';
import 'transaction_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.read<TransactionProvider>().watchTransactions(user.uid);
      }
    });
  }

  Future<void> _confirmDelete(TransactionModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
            'Apakah Anda yakin ingin menghapus transaksi "${transaction.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final provider = context.read<TransactionProvider>();
      final success = await provider.deleteTransaction(transaction.id);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Transaksi berhasil dihapus'
              : 'Gagal menghapus transaksi'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildDashboard() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final colorScheme = Theme.of(context).colorScheme;
        return RefreshIndicator(
          onRefresh: () async {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              provider.watchTransactions(user.uid);
            }
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Balance Card
                      Card(
                        elevation: 0,
                        color: colorScheme.primaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Saldo Bersih',
                                    style: TextStyle(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _currencyFormat.format(provider.balance),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${provider.transactionCount} transaksi',
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Income / Expense Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              context,
                              'Pemasukan',
                              provider.totalIncome,
                              Icons.arrow_downward_rounded,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              context,
                              'Pengeluaran',
                              provider.totalExpense,
                              Icons.arrow_upward_rounded,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Filter & Search Bar
                      Text(
                        'Riwayat Transaksi',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari transaksi...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                        ),
                        onChanged: provider.setSearchQuery,
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(context, provider, 'all', 'Semua'),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                                context, provider, 'income', 'Pemasukan'),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                                context, provider, 'expense', 'Pengeluaran'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              // Transaction List
              _buildTransactionList(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, String label, double amount,
      IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _currencyFormat.format(amount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, TransactionProvider provider,
      String value, String label) {
    final isSelected = provider.filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => provider.setFilter(value),
    );
  }

  Widget _buildTransactionList(
      BuildContext context, TransactionProvider provider) {
    if (provider.state == ViewState.loading) {
      return const SliverFillRemaining(
        child: LoadingWidget(message: 'Memuat transaksi...'),
      );
    }

    if (provider.state == ViewState.error) {
      return SliverFillRemaining(
        child: AppErrorWidget(
          message: provider.errorMessage ?? 'Terjadi kesalahan',
        ),
      );
    }

    final transactions = provider.transactions;

    if (transactions.isEmpty) {
      return const SliverFillRemaining(
        child: EmptyWidget(
          title: 'Belum ada transaksi',
          subtitle: 'Tekan tombol + untuk menambahkan transaksi baru',
          icon: Icons.receipt_long_rounded,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final transaction = transactions[index];
          return _buildTransactionTile(context, transaction);
        },
        childCount: transactions.length,
      ),
    );
  }

  Widget _buildTransactionTile(
      BuildContext context, TransactionModel transaction) {
    final isIncome = transaction.type == TransactionType.income;
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text('Hapus transaksi "${transaction.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (direction) async {
        final messenger = ScaffoldMessenger.of(context);
        final provider = context.read<TransactionProvider>();
        final success = await provider.deleteTransaction(transaction.id);
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Transaksi berhasil dihapus'
                : 'Gagal menghapus transaksi'),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isIncome
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
          title: Text(
            transaction.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(transaction.category),
              Text(
                DateFormat('dd MMM yyyy', 'id_ID').format(transaction.date),
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${_currencyFormat.format(transaction.amount)}',
                style: TextStyle(
                  color: isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            TransactionFormScreen(transaction: transaction),
                      ),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _confirmDelete(transaction),
                    child: Icon(
                      Icons.delete_rounded,
                      size: 18,
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
          isThreeLine: true,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TransactionFormScreen(transaction: transaction),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboard(),
      const ApiListScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Kas Kecil' : 'Produk'),
        centerTitle: false,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final userEmail = auth.user?.email;
              final avatarLetter = (userEmail != null && userEmail.isNotEmpty)
                  ? userEmail[0].toUpperCase()
                  : 'U';
              return PopupMenuButton<String>(
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    avatarLetter,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Akun',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          userEmail ?? '',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded),
                        SizedBox(width: 8),
                        Text('Keluar'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'logout') {
                    final txProvider = context.read<TransactionProvider>();
                    final authProv = context.read<AuthProvider>();
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Keluar'),
                        content: const Text('Apakah Anda yakin ingin keluar?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Keluar'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      txProvider.clearTransactions();
                      await authProv.logout();
                    }
                  }
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TransactionFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Kas Kecil',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag_rounded),
            label: 'Produk',
          ),
        ],
      ),
    );
  }
}
