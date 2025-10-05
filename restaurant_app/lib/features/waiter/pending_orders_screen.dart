import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/order.dart';
import 'cart_screen.dart';

class PendingOrdersScreen extends StatelessWidget {
  const PendingOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(name: 'USD');
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 600;
    final horizontalPadding = isCompact ? 16.0 : 24.0;
    final topPadding = isCompact ? 16.0 : 20.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF6CC), Color(0xFFFFE082)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          topPadding,
                          horizontalPadding,
                          isCompact ? 8 : 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.receipt_long, size: 32, color: Colors.black),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pedidos pendientes',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Gestiona los pedidos que siguen abiertos'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Body
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          child: Container(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('orders')
                                  .where('status', isEqualTo: 'open')
                                  // Si quieres ordenar en la query, agrega orderBy y crea índice si te lo pide:
                                  // .orderBy('createdAt', descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return const Center(child: Text('No hay pedidos pendientes.'));
                                }

                                // Mapear y ORDENAR EN MEMORIA para evitar índice compuesto
                                final orders = snapshot.data!.docs
                                    .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
                                    .toList()
                                  ..sort(
                                    (a, b) => b.createdAt.compareTo(a.createdAt),
                                  );

                                return ListView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                    horizontalPadding,
                                    20,
                                    horizontalPadding,
                                    20,
                                  ),
                                  itemCount: orders.length,
                                  itemBuilder: (context, index) {
                                    final order = orders[index];

                                    final subtitleParts = <String>[
                                      if (order.tableNumber != null)
                                        'Mesa #${order.tableNumber}'
                                      else
                                        'Pedido online',
                                      'Canal: ${_channelLabel(order.channel)}',
                                      'Creado: ${DateFormat.Hm().format(order.createdAt)}',
                                    ];

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: ListTile(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => CartScreen(orderId: order.id),
                                            ),
                                          );
                                        },
                                        leading: CircleAvatar(
                                          backgroundColor: const Color(0xFFFFC107).withOpacity(.18),
                                          foregroundColor: Colors.black,
                                          child: Text('#${order.orderNumber}'),
                                        ),
                                        title: Text(
                                          order.items.isEmpty
                                              ? 'Pedido sin productos'
                                              : order.items.first.name,
                                        ),
                                        subtitle: Text(subtitleParts.join(' · ')),
                                        trailing: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              currencyFormat.format(order.total),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'Ver detalles',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
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
