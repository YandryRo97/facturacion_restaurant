import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';

class ExpenseRepository {
  ExpenseRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> addExpense(Expense expense) async {
    await _db.collection('expenses').add({
      ...expense.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _updateSummariesWithDelta(expense.date, expense.amount);
  }

  Future<void> updateExpense({
    required Expense original,
    required Expense updated,
  }) async {
    final docRef = _db.collection('expenses').doc(original.id);

    await _db.runTransaction((trx) async {
      trx.update(docRef, updated.toMap());

      final originalDay = _formatDay(original.date);
      final updatedDay = _formatDay(updated.date);

      if (originalDay == updatedDay) {
        final diff = updated.amount - original.amount;
        if (diff != 0) {
          _applySummaryDelta(trx, updated.date, diff);
        }
      } else {
        _applySummaryDelta(trx, original.date, -original.amount);
        _applySummaryDelta(trx, updated.date, updated.amount);
      }
    });
  }

  Future<void> deleteExpense(Expense expense) async {
    final docRef = _db.collection('expenses').doc(expense.id);

    await _db.runTransaction((trx) async {
      trx.delete(docRef);
      _applySummaryDelta(trx, expense.date, -expense.amount);
    });
  }

  Future<void> _updateSummariesWithDelta(DateTime date, double amountDelta) async {
    if (amountDelta == 0) return;
    await _db.runTransaction((trx) async {
      _applySummaryDelta(trx, date, amountDelta);
    });
  }

  void _applySummaryDelta(Transaction trx, DateTime date, double amountDelta) {
    if (amountDelta == 0) return;
    final normalized = DateTime(date.year, date.month, date.day);
    final dayId = _formatDay(normalized);
    final monthId = _formatMonth(normalized);
    final dailyRef =
        _db.collection('summaries').doc('daily').collection('docs').doc(dayId);
    final monthlyRef =
        _db.collection('summaries').doc('monthly').collection('docs').doc(monthId);

    trx.set(
      dailyRef,
      {'expensesTotal': FieldValue.increment(amountDelta)},
      SetOptions(merge: true),
    );
    trx.set(
      monthlyRef,
      {'expensesTotal': FieldValue.increment(amountDelta)},
      SetOptions(merge: true),
    );
  }

  String _formatDay(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatMonth(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
  }
}
