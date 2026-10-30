// lib/screens/transaction_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class TransactionFormScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const TransactionFormScreen({super.key, this.transaction});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String _selectedCategory = 'Lainnya';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  bool get _isEditing => widget.transaction != null;

  static const List<String> _incomeCategories = [
    'Gaji',
    'Bonus',
    'Freelance',
    'Investasi',
    'Penjualan',
    'Lainnya',
  ];

  static const List<String> _expenseCategories = [
    'Makanan & Minuman',
    'Transportasi',
    'Belanja',
    'Tagihan',
    'Hiburan',
    'Kesehatan',
    'Pendidikan',
    'Lainnya',
  ];

  List<String> get _categories => _selectedType == TransactionType.income
      ? _incomeCategories
      : _expenseCategories;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.transaction!;
      _titleController.text = t.title;
      _amountController.text = t.amount.toStringAsFixed(0);
      _descriptionController.text = t.description;
      _selectedType = t.type;
      _selectedCategory = t.category;
      _selectedDate = t.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _save() {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengguna tidak ditemukan')),
      );
      return;
    }

    _isSaving = true;

    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<TransactionProvider>();
    final now = DateTime.now();
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

    // Ensure category is valid for selected type
    String category = _selectedCategory;
    if (!_categories.contains(category)) {
      category = 'Lainnya';
    }

    final isEditing = _isEditing;
    final successMessage = isEditing
        ? 'Transaksi berhasil diperbarui'
        : 'Transaksi berhasil ditambahkan';

    // Langsung kembali ke halaman home tanpa menunggu network loading
    Navigator.of(context).pop();

    // Langsung tampilkan notifikasi berhasil
    messenger.showSnackBar(
      SnackBar(
        content: Text(successMessage),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    // Jalankan operasi Firestore di background
    if (isEditing) {
      final updated = widget.transaction!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        amount: amount,
        type: _selectedType,
        category: category,
        date: _selectedDate,
        updatedAt: now,
      );
      provider.updateTransaction(updated).then((success) {
        if (!success) {
          messenger.showSnackBar(
            SnackBar(
              content:
                  Text(provider.errorMessage ?? 'Gagal memperbarui transaksi'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    } else {
      final newTransaction = TransactionModel(
        id: '',
        ownerId: user.uid,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        amount: amount,
        type: _selectedType,
        category: category,
        date: _selectedDate,
        createdAt: now,
        updatedAt: now,
      );
      provider.addTransaction(newTransaction).then((success) {
        if (!success) {
          messenger.showSnackBar(
            SnackBar(
              content:
                  Text(provider.errorMessage ?? 'Gagal menambahkan transaksi'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaksi' : 'Tambah Transaksi'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Type Selector
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jenis Transaksi',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTypeButton(
                                  context,
                                  TransactionType.income,
                                  'Pemasukan',
                                  Icons.arrow_downward_rounded,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTypeButton(
                                  context,
                                  TransactionType.expense,
                                  'Pengeluaran',
                                  Icons.arrow_upward_rounded,
                                  Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Form Fields
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Judul Transaksi',
                              prefixIcon: Icon(Icons.title_rounded),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Judul tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Nominal (Rp)',
                              prefixIcon: Icon(Icons.payments_rounded),
                              border: OutlineInputBorder(),
                              hintText: '0',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nominal tidak boleh kosong';
                              }
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return 'Masukkan nominal yang valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _categories.contains(_selectedCategory)
                                ? _selectedCategory
                                : _categories.first,
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                              prefixIcon: Icon(Icons.category_rounded),
                              border: OutlineInputBorder(),
                            ),
                            items: _categories
                                .map((cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedCategory = value);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Deskripsi (opsional)',
                              prefixIcon: Icon(Icons.description_rounded),
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Date picker
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(8),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Tanggal',
                                prefixIcon: Icon(Icons.calendar_today_rounded),
                                border: OutlineInputBorder(),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('dd MMMM yyyy', 'id_ID')
                                        .format(_selectedDate),
                                  ),
                                  Icon(
                                    Icons.edit_calendar_rounded,
                                    color: colorScheme.primary,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isEditing ? 'Simpan Perubahan' : 'Tambah Transaksi',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    BuildContext context,
    TransactionType type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => setState(() {
        _selectedType = type;
        _selectedCategory = type == TransactionType.income
            ? _incomeCategories.first
            : _expenseCategories.first;
      }),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? color
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected
                    ? color
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? color
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
