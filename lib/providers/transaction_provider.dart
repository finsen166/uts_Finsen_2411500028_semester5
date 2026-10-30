// lib/providers/transaction_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import 'view_state.dart';

class TransactionProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  ViewState _state = ViewState.initial;
  String? _errorMessage;
  List<TransactionModel> _transactions = [];
  StreamSubscription<List<TransactionModel>>? _subscription;
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'income', 'expense'

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  String get filterType => _filterType;
  String get searchQuery => _searchQuery;

  List<TransactionModel> get transactions {
    List<TransactionModel> filtered = _transactions;

    // Apply type filter
    if (_filterType == 'income') {
      filtered =
          filtered.where((t) => t.type == TransactionType.income).toList();
    } else if (_filterType == 'expense') {
      filtered =
          filtered.where((t) => t.type == TransactionType.expense).toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        return t.title.toLowerCase().contains(query) ||
            t.description.toLowerCase().contains(query) ||
            t.category.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  int get transactionCount => _transactions.length;

  void _setState(ViewState state, {String? error}) {
    _state = state;
    _errorMessage = error;
    notifyListeners();
  }

  void setFilter(String filterType) {
    _filterType = filterType;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void watchTransactions(String ownerId) {
    _cancelSubscription();
    _setState(ViewState.loading);

    _subscription =
        _firestoreService.watchTransactions(ownerId).listen((transactions) {
      _transactions = transactions;
      _setState(transactions.isEmpty ? ViewState.empty : ViewState.loaded);
    }, onError: (error) {
      _setState(ViewState.error,
          error: 'Gagal memuat transaksi: ${error.toString()}');
    });
  }

  Future<bool> addTransaction(TransactionModel transaction) async {
    try {
      await _firestoreService.addTransaction(transaction);
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambahkan transaksi: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTransaction(TransactionModel transaction) async {
    try {
      await _firestoreService.updateTransaction(transaction);
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengubah transaksi: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(String transactionId) async {
    try {
      await _firestoreService.deleteTransaction(transactionId);
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus transaksi: $e';
      notifyListeners();
      return false;
    }
  }

  void _cancelSubscription() {
    _subscription?.cancel();
    _subscription = null;
  }

  void clearTransactions() {
    _cancelSubscription();
    _transactions = [];
    _searchQuery = '';
    _filterType = 'all';
    _setState(ViewState.initial);
  }

  @override
  void dispose() {
    _cancelSubscription();
    super.dispose();
  }
}
