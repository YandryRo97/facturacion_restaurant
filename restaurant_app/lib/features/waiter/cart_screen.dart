import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../repositories/order_repository.dart';
import 'menu_screen.dart';

class CartScreen extends StatelessWidget {
  CartScreen({super.key, required this.orderId});

  final String orderId;
  final OrderRepository _orderRepository = OrderRepository();

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(name: 'USD');
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 600;
    final horizontalPadding = isCompact ? 16.0 : 24.0;
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
            final paymentMethod = data['paymentMethod'] as String?;

            Future<void> finalizeOrder() async {
              final method = await _selectPaymentMethod(context);
              if (method == null) return;
              try {
                await _orderRepository.updateOrderStatus(
                  orderId: orderId,
                  status: 'paid',
                  paymentMethod: method,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pedido finalizado correctamente.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se pudo finalizar el pedido.')),
                  );
                }
              }
            }

            Future<void> addMoreItems() async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MenuScreen(
                    existingOrderId: orderId,
                    tableId: data['tableId'] as String?,
                    tableNumber: tableNumber,
                    initialChannel: channel,
                  ),
                ),
              );
              if (result == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Productos agregados al pedido.')),
                );
              }
            }

            return SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(horizontalPadding),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: LayoutBuilder(
                                  builder: (context, contentConstraints) {
                                    final compactHeader = contentConstraints.maxWidth < 500;
                                    final detailsText = [
                                      if (tableNumber != null) 'Mesa #$tableNumber',
                                      'Canal: ${_channelLabel(channel)}',
                                      'Estado: ${_statusLabel(status)}',
                                      if (paymentMethod != null)
                                        'Pago: ${_paymentMethodLabel(paymentMethod)}',
                                    ].join(' · ');
                                    final chip = Chip(
                                      backgroundColor: Colors.black,
                                      labelStyle: const TextStyle(color: Colors.white),
                                      label: Text(currencyFormat.format(total)),
                                    );
                                    return compactHeader
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(Icons.receipt_long, size: 32),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'Resumen del pedido',
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .titleMedium
                                                              ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight.bold),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(detailsText),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              chip,
                                            ],
                                          )
                                        : Row(
                                            children: [
                                              const Icon(Icons.receipt_long, size: 32),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Resumen del pedido',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight.bold),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(detailsText),
                                                  ],
                                                ),
                                              ),
                                              chip,
                                            ],
                                          );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: items.isEmpty
                                ? const Center(
                                    child: Text('Aún no hay productos en este pedido.'),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: horizontalPadding,
                                    ),
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                      final item = items[index];
                                      final qty = (item['qty'] as num).toInt();
                                      final unit = (item['unitPrice'] as num).toDouble();
                                      final subtotal =
                                          (item['subtotal'] as num).toDouble();
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(18)),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: const Color(0xFFFFC107)
                                                .withOpacity(.2),
                                            child: Text('${index + 1}'),
                                          ),
                                          title: Text(
                                              item['name'] as String? ?? 'Producto'),
                                          subtitle: Text(
                                              '$qty × ${currencyFormat.format(unit)}'),
                                          trailing: Text(
                                            currencyFormat.format(subtotal),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          if (status == 'open')
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                0,
                                horizontalPadding,
                                isCompact ? 16 : 20,
                              ),
                              child: isCompact
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: addMoreItems,
                                          icon: const Icon(Icons.playlist_add),
                                          label: const Text('Agregar productos'),
                                        ),
                                        const SizedBox(height: 12),
                                        FilledButton.icon(
                                          onPressed: finalizeOrder,
                                          icon: const Icon(Icons.check_circle_outline),
                                          label: const Text('Finalizar pedido'),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: addMoreItems,
                                            icon: const Icon(Icons.playlist_add),
                                            label: const Text('Agregar productos'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: FilledButton.icon(
                                            onPressed: finalizeOrder,
                                            icon:
                                                const Icon(Icons.check_circle_outline),
                                            label: const Text('Finalizar pedido'),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: Colors.black,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
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

Future<String?> _selectPaymentMethod(BuildContext context) async {
  return showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Selecciona el método de pago',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Efectivo'),
              onTap: () => Navigator.of(context).pop('cash'),
            ),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Tarjeta'),
              onTap: () => Navigator.of(context).pop('card'),
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Otro'),
              onTap: () => Navigator.of(context).pop('other'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

String _paymentMethodLabel(String method) {
  switch (method) {
    case 'cash':
      return 'Efectivo';
    case 'card':
      return 'Tarjeta';
    case 'other':
      return 'Otro';
    default:
      return method;
  }
}
