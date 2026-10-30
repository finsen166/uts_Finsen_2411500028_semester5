// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _transactionsRef(String ownerId) {
    return _db.collection('transactions');
  }

  // Add a new transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    await _transactionsRef(transaction.ownerId).add(transaction.toFirestore());
  }

  // Get transactions once (Future)
  Future<List<TransactionModel>> getTransactions(String ownerId) async {
    final snapshot = await _db
        .collection('transactions')
        .where('ownerId', isEqualTo: ownerId)
        .get();

    final list = snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList();

    // Sort client-side to avoid requiring composite index
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // Watch transactions as a stream
  Stream<List<TransactionModel>> watchTransactions(String ownerId) {
    return _db
        .collection('transactions')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
      // Sort client-side
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  // Update an existing transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    final updatedData = transaction.toFirestore();
    updatedData['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _db
        .collection('transactions')
        .doc(transaction.id)
        .update(updatedData);
  }

  // Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    await _db.collection('transactions').doc(transactionId).delete();
  }
}
