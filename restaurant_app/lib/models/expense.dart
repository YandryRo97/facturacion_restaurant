class Expense {
final String id;
final String category;
final double amount;
final String note;
final DateTime date;


Expense({required this.id, required this.category, required this.amount, required this.note, required this.date});


factory Expense.fromMap(String id, Map<String, dynamic> data) => Expense(
id: id,
category: data['category'] ?? 'General',
amount: (data['amount'] ?? 0).toDouble(),
note: data['note'] ?? '',
date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
);


Map<String, dynamic> toMap() => {
'category': category,
'amount': amount,
'note': note,
'date': FieldValue.serverTimestamp(),
};
}