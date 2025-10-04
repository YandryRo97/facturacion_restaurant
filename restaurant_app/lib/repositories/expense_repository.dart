import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';


class ExpenseRepository {
final _db = FirebaseFirestore.instance;


Future<void> addExpense(Expense e) async {
await _db.collection('expenses').add(e.toMap());


final now = Timestamp.now().toDate();
final dayId = '${now.year.toString().padLeft(4,'0')}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
final monthId = '${now.year.toString().padLeft(4,'0')}-${now.month.toString().padLeft(2,'0')}';
final dailyRef = _db.collection('summaries').doc('daily').collection('docs').doc(dayId);
final monthlyRef = _db.collection('summaries').doc('monthly').collection('docs').doc(monthId);
await _db.runTransaction((trx) async {
trx.set(dailyRef, {'expensesTotal': FieldValue.increment(e.amount)}, SetOptions(merge: true));
trx.set(monthlyRef, {'expensesTotal': FieldValue.increment(e.amount)}, SetOptions(merge: true));
});
}
}