import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/menu_item.dart';
import '../../models/order.dart';
import '../../repositories/order_repository.dart';
import 'cart_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, this.tableId});

  final String? tableId;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final List<OrderItem> _cart = [];
  final OrderRepository _orderRepository = OrderRepository();
  final NumberFormat _currencyFormat = NumberFormat.simpleCurrency(locale: 'es');

  bool _creatingOrder = false;

  void _addToCart(MenuItemModel item) {
    setState(() {
      final index = _cart.indexWhere((entry) => entry.menuItemId == item.id);
      if (index == -1) {
        _cart.add(
          OrderItem(
            menuItemId: item.id,
            name: item.name,
            unitPrice: item.price,
            qty: 1,
          ),
        );
      } else {
        final current = _cart[index];
        _cart[index] = current.copyWith(qty: current.qty + 1);
      }
    });
  }

  void _increaseQty(OrderItem item) {
    setState(() {
      final index = _cart.indexOf(item);
      if (index == -1) return;
      _cart[index] = item.copyWith(qty: item.qty + 1);
    });
  }

  void _decreaseQty(OrderItem item) {
    setState(() {
      final index = _cart.indexOf(item);
      if (index == -1) return;
      if (item.qty <= 1) {
        _cart.removeAt(index);
      } else {
        _cart[index] = item.copyWith(qty: item.qty - 1);
      }
    });
  }

  void _removeFromCart(OrderItem item) {
    setState(() {
      _cart.remove(item);
    });
  }

  double get _cartTotal =>
      _cart.fold<double>(0, (total, item) => total + item.subtotal);

  Future<void> _createOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para crear pedidos.')),
      );
      return;
    }

    setState(() => _creatingOrder = true);
    try {
      final orderId = await _orderRepository.createOrder(
        waiterId: user.uid,
        tableId: widget.tableId,
        channel: widget.tableId == null ? 'online' : 'dine-in',
        items: List<OrderItem>.from(_cart),
      );
      if (!mounted) return;
      setState(() {
        _cart.clear();
      });
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CartScreen(orderId: orderId)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear el pedido.')),
      );
    } finally {
      if (mounted) {
        setState(() => _creatingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tableId == null
            ? 'Menú (online)'
            : 'Menú mesa ${widget.tableId}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('menu_items')
                  .where('isAvailable', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data!.docs
                    .map((doc) => MenuItemModel.fromMap(doc.id, doc.data()))
                    .toList();
                if (items.isEmpty) {
                  return const Center(child: Text('No hay elementos disponibles.'));
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(item.name.isNotEmpty ? item.name[0] : '?')),
                        title: Text(item.name),
                        subtitle: Text(item.category),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_currencyFormat.format(item.price)),
                            TextButton(
                              onPressed: () => _addToCart(item),
                              child: const Text('Agregar'),
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
          if (_cart.isNotEmpty) _buildCartSummary(),
        ],
      ),
      floatingActionButton: _cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _creatingOrder ? null : _createOrder,
              label: Text(
                _creatingOrder
                    ? 'Creando pedido...'
                    : 'Crear pedido (${_currencyFormat.format(_cartTotal)})',
              ),
              icon: _creatingOrder
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.shopping_cart_checkout),
            ),
    );
  }

  Widget _buildCartSummary() {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pedido actual',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            for (final item in _cart)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.name),
                subtitle: Text(
                  '${item.qty} × ${_currencyFormat.format(item.unitPrice)} = ${_currencyFormat.format(item.subtotal)}',
                ),
                trailing: Wrap(
                  spacing: 0,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => _decreaseQty(item),
                    ),
                    Text('${item.qty}'),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => _increaseQty(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeFromCart(item),
                    ),
                  ],
                ),
              ),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: ${_currencyFormat.format(_cartTotal)}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
