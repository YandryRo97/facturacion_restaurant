import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(name: 'USD');
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId)
              .snapshots(),
          builder: (context, snapshot) {
            final orderNumber = (snapshot.data?.data()?['orderNumber'] as num?)
                    ?.toInt() ??
                null;
            if (orderNumber == null) {
              return Text('Pedido #$orderId');
            }
            return Text('Pedido #$orderNumber');
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF6CC), Color(0xFFFFE082)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!.data();
            if (data == null) {
              return const Center(child: Text('No se encontró la información del pedido.'));
            }
            final items = (data['items'] as List).cast<Map<String, dynamic>>();
            final total = (data['total'] ?? 0).toDouble();
            final status = (data['status'] ?? 'open') as String;
            final channel = (data['channel'] ?? 'dine-in') as String;
            final tableNumber = (data['tableNumber'] as num?)?.toInt();

            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_long, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Resumen del pedido',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      if (tableNumber != null) 'Mesa #$tableNumber',
                                      'Canal: ${_channelLabel(channel)}',
                                      'Estado: ${_statusLabel(status)}',
                                    ].join(' · '),
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              backgroundColor: Colors.black,
                              labelStyle: const TextStyle(color: Colors.white),
                              label: Text(currencyFormat.format(total)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final qty = (item['qty'] as num).toInt();
                        final unit = (item['unitPrice'] as num).toDouble();
                        final subtotal = (item['subtotal'] as num).toDouble();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFFFC107).withOpacity(.2),
                              child: Text('${index + 1}'),
                            ),
                            title: Text(item['name'] as String? ?? 'Producto'),
                            subtitle: Text('$qty × ${currencyFormat.format(unit)}'),
                            trailing: Text(
                              currencyFormat.format(subtotal),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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

String _channelLabel(String channel) {
  switch (channel) {
    case 'dine-in':
      return 'En mesa';
    case 'online':
      return 'Online';
    default:
      return channel;
  }
}
