import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/menu_item.dart';
import '../../models/order.dart';
import '../../repositories/order_repository.dart';
import 'cart_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({
    super.key,
    this.tableId,
    this.tableNumber,
    this.existingOrderId,
    this.initialChannel,
  });

  final String? tableId;
  final int? tableNumber;
  final String? existingOrderId;
  final String? initialChannel;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final List<OrderItem> _cart = [];
  final OrderRepository _orderRepository = OrderRepository();
  final NumberFormat _currencyFormat = NumberFormat.simpleCurrency(name: 'USD');

  bool _creatingOrder = false;

  bool get _isEditingOrder => widget.existingOrderId != null;

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
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para crear pedidos.')),
      );
      return;
    }

    setState(() => _creatingOrder = true);
    try {
      final channel = widget.initialChannel ??
          (widget.tableId == null ? 'online' : 'dine-in');
      if (_isEditingOrder) {
        await _orderRepository.addItemsToOrder(
          orderId: widget.existingOrderId!,
          items: List<OrderItem>.from(_cart),
        );
        if (!mounted) return;
        setState(() {
          _cart.clear();
        });
        Navigator.of(context).pop(true);
      } else {
        final orderId = await _orderRepository.createOrder(
          waiterId: user.uid,
          tableId: widget.tableId,
          tableNumber: widget.tableNumber,
          channel: channel,
          items: List<OrderItem>.from(_cart),
        );
        if (!mounted) return;
        setState(() {
          _cart.clear();
        });
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CartScreen(orderId: orderId)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditingOrder
                ? 'No se pudo actualizar el pedido.'
                : 'No se pudo crear el pedido.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _creatingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 600;
    final horizontalPadding = isCompact ? 16.0 : 24.0;
    final topPadding = isCompact ? 12.0 : 16.0;
    final title = _isEditingOrder
        ? 'Agregar productos'
        : widget.tableId == null
            ? 'Pedido digital'
            : 'Mesa ${widget.tableNumber ?? widget.tableId}';
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
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          topPadding,
                          horizontalPadding,
                          topPadding,
                        ),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Icon(Icons.lunch_dining, size: 32, color: Colors.black),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                const Text('Elige tus favoritos de Ing Burger'),
                              ],
                            ),
                          ],
                        ),
                      ),
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
                                  return const Center(
                                    child: Text('No hay elementos disponibles por ahora.'),
                                  );
                                }
                                final grouped = <String, List<MenuItemModel>>{};
                                for (final item in items) {
                                  grouped.putIfAbsent(item.category, () => []).add(item);
                                }
                                return ListView(
                                  padding: EdgeInsets.fromLTRB(
                                    horizontalPadding,
                                    20,
                                    horizontalPadding,
                                    20,
                                  ),
                                  children: grouped.entries.map((entry) {
                                    final category = entry.key;
                                    final categoryItems = entry.value;
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category,
                                          style:
                                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                        ),
                                        const SizedBox(height: 12),
                                        ...categoryItems.map(
                                          (item) => _MenuCard(
                                            item: item,
                                            currencyFormat: _currencyFormat,
                                            onAdd: () => _addToCart(item),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      if (_cart.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: _buildCartSummary(),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: _cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              onPressed: _creatingOrder ? null : _createOrder,
              label: Text(
                _creatingOrder
                    ? (_isEditingOrder
                        ? 'Actualizando...'
                        : 'Creando pedido...')
                    : _isEditingOrder
                        ? 'Agregar (${_currencyFormat.format(_cartTotal)})'
                        : 'Crear pedido (${_currencyFormat.format(_cartTotal)})',
              ),
              icon: _creatingOrder
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(_isEditingOrder
                      ? Icons.playlist_add_circle
                      : Icons.shopping_cart_checkout),
            ),
    );
  }

  Widget _buildCartSummary() {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_basket_outlined),
                const SizedBox(width: 8),
                Text(
                  'Pedido actual',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._cart.map((item) {
              return ListTile(
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
              );
            }),
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

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.item,
    required this.currencyFormat,
    required this.onAdd,
  });

  final MenuItemModel item;
  final NumberFormat currencyFormat;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;
        final avatar = CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFFFC107).withOpacity(.2),
          child: Text(
            item.name.isNotEmpty ? item.name[0].toUpperCase() : '🍔',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        );
        final description = Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                item.description?.isNotEmpty == true
                    ? item.description!
                    : 'Perfecto para compartir y disfrutar.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                currencyFormat.format(item.price),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
        final button = FilledButton(
          onPressed: onAdd,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text('Agregar'),
        );
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          avatar,
                          const SizedBox(width: 16),
                          description,
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: button,
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      avatar,
                      const SizedBox(width: 16),
                      description,
                      const SizedBox(width: 12),
                      button,
                    ],
                  ),
          ),
        );
      },
    );
  }
}
