import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final String _dayId;
  late final String _monthId;
  final NumberFormat _currencyFormat = NumberFormat.simpleCurrency(locale: 'es');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dayId = DateFormat('yyyy-MM-dd').format(now);
    _monthId = DateFormat('yyyy-MM').format(now);
  }

  @override
  Widget build(BuildContext context) {
    final dailyRef = FirebaseFirestore.instance
        .collection('summaries')
        .doc('daily')
        .collection('docs')
        .doc(_dayId);
    final monthlyRef = FirebaseFirestore.instance
        .collection('summaries')
        .doc('monthly')
        .collection('docs')
        .doc(_monthId);
    final recentOrdersQuery = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(5);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin · Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Hoy'),
            const SizedBox(height: 8),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: dailyRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data!.data() ?? const {};
                final sales = (data['salesTotal'] ?? 0).toDouble();
                final orders = (data['ordersCount'] ?? 0) as num;
                final expenses = (data['expensesTotal'] ?? 0).toDouble();
                final net = (data['netTotal'] ?? (sales - expenses)).toDouble();
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricTile(
                      title: 'Ventas',
                      value: _currencyFormat.format(sales),
                      icon: Icons.attach_money,
                    ),
                    _MetricTile(
                      title: 'Pedidos',
                      value: orders.toString(),
                      icon: Icons.receipt_long,
                    ),
                    _MetricTile(
                      title: 'Gastos',
                      value: _currencyFormat.format(expenses),
                      icon: Icons.money_off,
                    ),
                    _MetricTile(
                      title: 'Neto',
                      value: _currencyFormat.format(net),
                      icon: Icons.trending_up,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Este mes'),
            const SizedBox(height: 8),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: monthlyRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data!.data() ?? const {};
                final sales = (data['salesTotal'] ?? 0).toDouble();
                final expenses = (data['expensesTotal'] ?? 0).toDouble();
                final dineIn = (data['dineInTotal'] ?? 0).toDouble();
                final online = (data['onlineTotal'] ?? 0).toDouble();
                final orders = (data['ordersCount'] ?? 0) as num;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricTile(
                      title: 'Ventas',
                      value: _currencyFormat.format(sales),
                      icon: Icons.shopping_bag,
                    ),
                    _MetricTile(
                      title: 'Pedidos',
                      value: orders.toString(),
                      icon: Icons.list_alt,
                    ),
                    _MetricTile(
                      title: 'Gastos',
                      value: _currencyFormat.format(expenses),
                      icon: Icons.request_quote,
                    ),
                    _MetricTile(
                      title: 'Dine-in',
                      value: _currencyFormat.format(dineIn),
                      icon: Icons.storefront,
                    ),
                    _MetricTile(
                      title: 'Online',
                      value: _currencyFormat.format(online),
                      icon: Icons.wifi,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Últimos pedidos'),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: recentOrdersQuery.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Text('Aún no hay pedidos.');
                }
                final docs = snapshot.data!.docs;
                return Column(
                  children: docs.map((doc) {
                    final data = doc.data();
                    final orderNumber = data['orderNumber'] ?? '-';
                    final total = (data['total'] ?? 0).toDouble();
                    final status = (data['status'] ?? 'open') as String;
                    final channel = (data['channel'] ?? 'dine-in') as String;
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    final dateStr = createdAt != null
                        ? DateFormat('dd/MM HH:mm').format(createdAt)
                        : '—';
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('$orderNumber'),
                        ),
                        title: Text('Total ${_currencyFormat.format(total)}'),
                        subtitle: Text('Canal: $channel · Estado: $status'),
                        trailing: Text(dateStr),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
