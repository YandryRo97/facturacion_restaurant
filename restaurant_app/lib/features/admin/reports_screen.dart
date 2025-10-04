import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late DateTimeRange _range;
  Future<_ReportData>? _reportFuture;
  final NumberFormat _currencyFormat = NumberFormat.simpleCurrency(name: 'USD');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final end = DateTime(now.year, now.month, now.day);
    _range = DateTimeRange(start: start, end: end);
    _reportFuture = _loadReport();
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _range,
      helpText: 'Selecciona el rango de fechas',
      locale: const Locale('es'),
    );
    if (picked != null) {
      setState(() {
        _range = DateTimeRange(
          start: DateTime(picked.start.year, picked.start.month, picked.start.day),
          end: DateTime(picked.end.year, picked.end.month, picked.end.day),
        );
        _reportFuture = _loadReport();
      });
    }
  }

  Future<_ReportData> _loadReport() async {
    final start = Timestamp.fromDate(_range.start);
    final endExclusive = Timestamp.fromDate(_range.end.add(const Duration(days: 1)));

    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'paid')
        .where('closedAt', isGreaterThanOrEqualTo: start)
        .where('closedAt', isLessThan: endExclusive)
        .orderBy('closedAt', descending: true)
        .get();

    double totalSales = 0;
    double dineInTotal = 0;
    double onlineTotal = 0;
    final Map<String, _DailySummary> daily = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final total = (data['total'] as num?)?.toDouble() ?? 0;
      final channel = (data['channel'] as String?) ?? 'dine-in';
      final closedAt = (data['closedAt'] as Timestamp?)?.toDate() ??
          (data['createdAt'] as Timestamp?)?.toDate();
      if (closedAt == null) continue;
      final dayKey = DateFormat('yyyy-MM-dd').format(closedAt);

      totalSales += total;
      if (channel == 'dine-in') {
        dineInTotal += total;
      } else {
        onlineTotal += total;
      }

      daily.update(
        dayKey,
        (value) => value.copyWith(
          totalSales: value.totalSales + total,
          ordersCount: value.ordersCount + 1,
          dineInTotal: channel == 'dine-in'
              ? value.dineInTotal + total
              : value.dineInTotal,
          onlineTotal: channel == 'online'
              ? value.onlineTotal + total
              : value.onlineTotal,
        ),
        ifAbsent: () => _DailySummary(
          date: DateFormat('yyyy-MM-dd').parse(dayKey),
          totalSales: total,
          ordersCount: 1,
          dineInTotal: channel == 'dine-in' ? total : 0,
          onlineTotal: channel == 'online' ? total : 0,
        ),
      );
    }

    final dailySummaries = daily.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return _ReportData(
      totalSales: totalSales,
      ordersCount: snapshot.docs.length,
      dineInTotal: dineInTotal,
      onlineTotal: onlineTotal,
      dailySummaries: dailySummaries,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reportes de ingresos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Consulta el historial de ventas por rango de fechas para tomar mejores decisiones.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    '${DateFormat('dd/MM/yyyy', 'es').format(_range.start)} - ${DateFormat('dd/MM/yyyy', 'es').format(_range.end)}',
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _reportFuture = _loadReport();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FutureBuilder<_ReportData>(
              future: _reportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text('No se pudieron cargar los reportes.'),
                    ),
                  );
                }
                final data = snapshot.data ??
                    const _ReportData(
                      totalSales: 0,
                      ordersCount: 0,
                      dineInTotal: 0,
                      onlineTotal: 0,
                      dailySummaries: [],
                    );

                if (data.ordersCount == 0) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('No hay ventas registradas en el periodo seleccionado.'),
                    ),
                  );
                }

                final averageTicket =
                    data.ordersCount == 0 ? 0 : data.totalSales / data.ordersCount;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.count(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 900 ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.6,
                      children: [
                        _ReportMetricTile(
                          title: 'Ventas totales',
                          value: _currencyFormat.format(data.totalSales),
                          icon: Icons.attach_money,
                          color: const Color(0xFF4CAF50),
                        ),
                        _ReportMetricTile(
                          title: 'Pedidos pagados',
                          value: data.ordersCount.toString(),
                          icon: Icons.receipt_long,
                          color: const Color(0xFF42A5F5),
                        ),
                        _ReportMetricTile(
                          title: 'Ticket promedio',
                          value: _currencyFormat.format(averageTicket),
                          icon: Icons.trending_up,
                          color: const Color(0xFFFFC107),
                        ),
                        _ReportMetricTile(
                          title: 'Ventas en salón',
                          value: _currencyFormat.format(data.dineInTotal),
                          icon: Icons.storefront,
                          color: const Color(0xFF00796B),
                        ),
                        _ReportMetricTile(
                          title: 'Ventas online',
                          value: _currencyFormat.format(data.onlineTotal),
                          icon: Icons.wifi,
                          color: const Color(0xFF00ACC1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Desglose diario',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.dailySummaries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final summary = data.dailySummaries[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF4CAF50).withOpacity(.15),
                              child: Text(DateFormat('dd').format(summary.date)),
                            ),
                            title: Text(DateFormat('EEEE d MMMM', 'es').format(summary.date)),
                            subtitle: Text(
                              'Pedidos: ${summary.ordersCount} · Salón: ${_currencyFormat.format(summary.dineInTotal)} · Online: ${_currencyFormat.format(summary.onlineTotal)}',
                            ),
                            trailing: Text(
                              _currencyFormat.format(summary.totalSales),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportMetricTile extends StatelessWidget {
  const _ReportMetricTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(.15),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
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
    );
  }
}

class _ReportData {
  const _ReportData({
    required this.totalSales,
    required this.ordersCount,
    required this.dineInTotal,
    required this.onlineTotal,
    required this.dailySummaries,
  });

  final double totalSales;
  final int ordersCount;
  final double dineInTotal;
  final double onlineTotal;
  final List<_DailySummary> dailySummaries;
}

class _DailySummary {
  const _DailySummary({
    required this.date,
    required this.totalSales,
    required this.ordersCount,
    required this.dineInTotal,
    required this.onlineTotal,
  });

  final DateTime date;
  final double totalSales;
  final int ordersCount;
  final double dineInTotal;
  final double onlineTotal;

  _DailySummary copyWith({
    double? totalSales,
    int? ordersCount,
    double? dineInTotal,
    double? onlineTotal,
  }) {
    return _DailySummary(
      date: date,
      totalSales: totalSales ?? this.totalSales,
      ordersCount: ordersCount ?? this.ordersCount,
      dineInTotal: dineInTotal ?? this.dineInTotal,
      onlineTotal: onlineTotal ?? this.onlineTotal,
    );
  }
}
