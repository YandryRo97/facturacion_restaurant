import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class DashboardScreen extends StatefulWidget {
const DashboardScreen({super.key});


@override
State<DashboardScreen> createState() => _DashboardScreenState();
}


class _DashboardScreenState extends State<DashboardScreen> {
late String dayId;
late String monthId;


@override
void initState() {
super.initState();
final now = DateTime.now();
dayId = DateFormat('yyyy-MM-dd').format(now);
monthId = DateFormat('yyyy-MM').format(now);
}


@override
Widget build(BuildContext context) {
final dailyRef = FirebaseFirestore.instance.collection('summaries').doc('daily').collection('docs').doc(dayId);
final monthlyRef = FirebaseFirestore.instance.collection('summaries').doc('monthly').collection('docs').doc(monthId);


return Scaffold(
appBar: AppBar(title: const Text('Admin · Dashboard')),
body: Padding(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text('Hoy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
const SizedBox(height: 8),
StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
stream: dailyRef.snapshots(),
builder: (context, snap) {
final m = snap.data?.data() ?? {};
final sales = (m['salesTotal'] ?? 0).toDouble();
final orders = (m['ordersCount'] ?? 0);
final expenses = (m['expensesTotal'] ?? 0).toDouble();
final net = (m['netTotal'] ?? (sales - expenses)).toDouble();
return Wrap(spacing: 12, runSpacing: 12, children: [
_tile('Ventas', sales),
_tile('Pedidos', orders.toDouble(), money: false),
_tile('Gastos', expenses),
_tile('Neto', net),
]);
},
),
const SizedBox(height: 24),
}