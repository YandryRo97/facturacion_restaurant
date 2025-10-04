import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  const Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.note,
    required this.date,
  });

  final String id;
  final String category;
  final double amount;
  final String note;
  final DateTime date;

  factory Expense.fromMap(String id, Map<String, dynamic> data) {
    final timestamp = data['date'] as Timestamp?;
    return Expense(
      id: id,
      category: data['category'] as String? ?? 'General',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      note: data['note'] as String? ?? '',
      date: timestamp?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'amount': amount,
      'note': note,
      'date': Timestamp.fromDate(date),
    };
  }
}
