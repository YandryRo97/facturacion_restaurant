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

    final now = Timestamp.now().toDate();
    final dayId =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final monthId =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    final dailyRef =
        _db.collection('summaries').doc('daily').collection('docs').doc(dayId);
    final monthlyRef =
        _db.collection('summaries').doc('monthly').collection('docs').doc(monthId);

    await _db.runTransaction((trx) async {
      trx.set(
        dailyRef,
        {'expensesTotal': FieldValue.increment(expense.amount)},
        SetOptions(merge: true),
      );
      trx.set(
        monthlyRef,
        {'expensesTotal': FieldValue.increment(expense.amount)},
        SetOptions(merge: true),
      );
    });
  }
}
