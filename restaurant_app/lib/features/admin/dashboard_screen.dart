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
  final NumberFormat _currencyFormat = NumberFormat.simpleCurrency(name: 'USD');

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
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, administrador',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Revisa el rendimiento de Ing Burger'),
                  ],
                ),
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.black,
                  child: const Icon(Icons.bar_chart_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Hoy'),
            const SizedBox(height: 12),
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
                return GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.6,
                  children: [
                    _MetricTile(
                      title: 'Ventas',
                      value: _currencyFormat.format(sales),
                      icon: Icons.attach_money,
                      accentColor: const Color(0xFF1DE9B6),
                    ),
                    _MetricTile(
                      title: 'Pedidos',
                      value: orders.toString(),
                      icon: Icons.receipt_long,
                      accentColor: const Color(0xFFFFC107),
                    ),
                    _MetricTile(
                      title: 'Gastos',
                      value: _currencyFormat.format(expenses),
                      icon: Icons.money_off,
                      accentColor: const Color(0xFFFF7043),
                    ),
                    _MetricTile(
                      title: 'Neto',
                      value: _currencyFormat.format(net),
                      icon: Icons.trending_up,
                      accentColor: const Color(0xFF42A5F5),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Este mes'),
            const SizedBox(height: 12),
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
                return GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 3,
                  children: [
                    _MetricTile(
                      title: 'Ventas',
                      value: _currencyFormat.format(sales),
                      icon: Icons.shopping_bag,
                      accentColor: const Color(0xFF4CAF50),
                    ),
                    _MetricTile(
                      title: 'Pedidos',
                      value: orders.toString(),
                      icon: Icons.list_alt,
                      accentColor: const Color(0xFF651FFF),
                    ),
                    _MetricTile(
                      title: 'Gastos',
                      value: _currencyFormat.format(expenses),
                      icon: Icons.request_quote,
                      accentColor: const Color(0xFFFF6F00),
                    ),
                    _MetricTile(
                      title: 'Dine-in',
                      value: _currencyFormat.format(dineIn),
                      icon: Icons.storefront,
                      accentColor: const Color(0xFF00796B),
                    ),
                    _MetricTile(
                      title: 'Online',
                      value: _currencyFormat.format(online),
                      icon: Icons.wifi,
                      accentColor: const Color(0xFF00ACC1),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Últimos pedidos'),
            const SizedBox(height: 12),
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
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              child: Text('$orderNumber'),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currencyFormat.format(total),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      _StatusChip(label: 'Canal: $channel'),
                                      _StatusChip(label: 'Estado: ${_statusLabel(status)}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(dateStr),
                          ],
                        ),
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
    required this.accentColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor),
              ),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: const Color(0xFFFFF3CD),
      side: const BorderSide(color: Color(0xFFFFC107)),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'open':
      return 'Abierto';
    case 'paid':
      return 'Pagado';
    case 'cancelled':
      return 'Cancelado';
    default:
      return status;
  }
}
