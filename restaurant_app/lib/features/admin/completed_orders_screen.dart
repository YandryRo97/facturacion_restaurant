import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/order.dart';
import '../../repositories/order_repository.dart';

class CompletedOrdersScreen extends StatefulWidget {
  const CompletedOrdersScreen({super.key});

  @override
  State<CompletedOrdersScreen> createState() => _CompletedOrdersScreenState();
}

class _CompletedOrdersScreenState extends State<CompletedOrdersScreen> {
  final NumberFormat _currencyFormat = NumberFormat.simpleCurrency(name: 'USD');
  final OrderRepository _orderRepository = OrderRepository();

  Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'paid')
        .orderBy('closedAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<void> _openEditor(OrderModel order) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CompletedOrderEditor(
          orderId: order.id,
          orderNumber: order.orderNumber,
          repository: _orderRepository,
        );
      },
    );
    if ((updated ?? false) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido actualizado correctamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pedidos completados',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Consulta y edita pedidos cerrados. Solo administradores pueden actualizar estos registros.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _ordersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error al cargar los pedidos: ${snapshot.error}'),
                    );
                  }
                  final docs = snapshot.data?.docs ?? const [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('Aún no hay pedidos completados.'),
                    );
                  }
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = OrderModel.fromMap(
                        docs[index].id,
                        docs[index].data(),
                      );
                      final closedAt = order.closedAt;
                      final closedAtLabel = closedAt != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(closedAt)
                          : 'Sin registrar';
                      final tableLabel = order.tableNumber != null
                          ? 'Mesa ${order.tableNumber}'
                          : 'Sin mesa';
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    child: Text('#${order.orderNumber}'),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _currencyFormat.format(order.total),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            Chip(
                                              label: Text('Canal: ${order.channel}'),
                                            ),
                                            Chip(
                                              label: Text(tableLabel),
                                            ),
                                            Chip(
                                              label: Text('Pago: ${order.paymentMethod ?? 'Sin registrar'}'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(closedAtLabel),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.icon(
                                  onPressed: () => _openEditor(order),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Editar pedido'),
                                ),
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
          ],
        ),
      ),
    );
  }
}

class CompletedOrderEditor extends StatefulWidget {
  const CompletedOrderEditor({
    required this.orderId,
    required this.orderNumber,
    required this.repository,
    super.key,
  });

  final String orderId;
  final int orderNumber;
  final OrderRepository repository;

  @override
  State<CompletedOrderEditor> createState() => _CompletedOrderEditorState();
}

class _CompletedOrderEditorState extends State<CompletedOrderEditor> {
  final NumberFormat _currencyFormat = NumberFormat.simpleCurrency(name: 'USD');
  final TextEditingController _paymentController = TextEditingController();
  final List<_EditableOrderItem> _items = [];

  OrderModel? _order;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _originalPaymentMethod;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();
      final data = snapshot.data();
      if (data == null) {
        setState(() {
          _error = 'El pedido ya no está disponible.';
          _isLoading = false;
        });
        return;
      }
      final order = OrderModel.fromMap(snapshot.id, data);
      _items
        ..clear()
        ..addAll(order.items.map((item) => _EditableOrderItem(item: item)));
      _paymentController.text = order.paymentMethod ?? '';
      setState(() {
        _order = order;
        _originalPaymentMethod = order.paymentMethod ?? '';
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'No se pudo cargar el pedido.';
        _isLoading = false;
      });
    }
  }

  double get _currentTotal {
    return _items.fold<double>(0, (total, item) => total + item.subtotal);
  }

  Future<void> _saveChanges() async {
    final order = _order;
    if (order == null) {
      return;
    }
    final trimmedPayment = _paymentController.text.trim();
    final itemsToUpdate =
        _items.where((element) => element.qty != element.initialQty).toList();
    final paymentChanged = trimmedPayment != (_originalPaymentMethod ?? '').trim();
    if (itemsToUpdate.isEmpty && !paymentChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cambios para guardar.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      for (final editable in itemsToUpdate) {
        await widget.repository.updateOrderItemQuantity(
          orderId: order.id,
          menuItemId: editable.item.menuItemId,
          quantity: editable.qty,
          allowClosedOrders: true,
        );
      }
      if (paymentChanged) {
        final doc =
            FirebaseFirestore.instance.collection('orders').doc(order.id);
        final updateData = <String, Object?>{
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (trimmedPayment.isEmpty) {
          updateData['paymentMethod'] = FieldValue.delete();
        } else {
          updateData['paymentMethod'] = trimmedPayment;
        }
        await doc.update(updateData);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron guardar los cambios.')),
      );
    }
  }

  void _incrementQty(int index) {
    setState(() {
      _items[index].qty++;
    });
  }

  void _decrementQty(int index) {
    setState(() {
      if (_items[index].qty > 0) {
        _items[index].qty--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Editar pedido #${widget.orderNumber}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    _error!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.red),
                  ),
                )
              else ...[
                Text(
                  'Productos',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (_items.isEmpty)
                  const Text('Este pedido no tiene productos registrados.')
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.item.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Unitario: ${_currencyFormat.format(item.item.unitPrice)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _isSaving ? null : () => _decrementQty(index),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              SizedBox(
                                width: 32,
                                child: Center(
                                  child: Text(
                                    '${item.qty}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _isSaving ? null : () => _incrementQty(index),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Text(_currencyFormat.format(item.subtotal)),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 20),
                Text(
                  'Método de pago',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _paymentController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    hintText: 'Ej. Efectivo, Tarjeta, Transferencia',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total actualizado',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      _currencyFormat.format(_currentTotal),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Guardar cambios'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableOrderItem {
  _EditableOrderItem({required this.item})
      : qty = item.qty,
        initialQty = item.qty;

  final OrderItem item;
  final int initialQty;
  int qty;

  double get subtotal => item.unitPrice * qty;
}
