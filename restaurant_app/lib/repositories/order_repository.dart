import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order.dart';

class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<int> _nextOrderNumber() async {
    final snapshot = await _db
        .collection('orders')
        .orderBy('orderNumber', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return 1;
    }
    final lastNumber = snapshot.docs.first.data()['orderNumber'] as num? ?? 0;
    return lastNumber.toInt() + 1;
  }

  Future<String> createOrder({
    required String waiterId,
    String? tableId,
    int? tableNumber,
    required String channel,
    required List<OrderItem> items,
  }) async {
    final orderNumber = await _nextOrderNumber();
    final total =
        items.fold<double>(0, (value, element) => value + element.subtotal);
    final doc = _db.collection('orders').doc();
    int? resolvedTableNumber = tableNumber;
    if (tableId != null && resolvedTableNumber == null) {
      final tableSnap = await _db.collection('tables').doc(tableId).get();
      resolvedTableNumber = (tableSnap.data()?['number'] as num?)?.toInt();
    }
    await doc.set({
      'orderNumber': orderNumber,
      'tableId': tableId,
      'tableNumber': resolvedTableNumber,
      'channel': channel,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': 'open',
      'waiterId': waiterId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (tableId != null) {
      await _db.collection('tables').doc(tableId).update({
        'status': 'occupied',
        'currentOrderId': doc.id,
      });
    }
    return doc.id;
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? paymentMethod,
  }) async {
    final doc = _db.collection('orders').doc(orderId);
    await _db.runTransaction((trx) async {
      final snapshot = await trx.get(doc);
      if (!snapshot.exists) {
        throw StateError('El pedido no existe');
      }
      final data = snapshot.data()!;
      trx.update(doc, {
        'status': status,
        if (status == 'paid') 'closedAt': FieldValue.serverTimestamp(),
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
      });
      final tableId = data['tableId'] as String?;
      if (tableId != null && (status == 'paid' || status == 'cancelled')) {
        trx.update(
          _db.collection('tables').doc(tableId),
          {
            'status': 'free',
            'currentOrderId': null,
          },
        );
      }
      if (status == 'paid') {
        final total = (data['total'] as num?)?.toDouble() ?? 0;
        final channel = (data['channel'] as String?) ?? 'dine-in';
        final now = Timestamp.now().toDate();
        final dayId =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final monthId =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
        final dailyRef =
            _db.collection('summaries').doc('daily').collection('docs').doc(dayId);
        final monthlyRef = _db
            .collection('summaries')
            .doc('monthly')
            .collection('docs')
            .doc(monthId);
        trx.set(
          dailyRef,
          {
            'salesTotal': FieldValue.increment(total),
            'ordersCount': FieldValue.increment(1),
            'dineInTotal': FieldValue.increment(channel == 'dine-in' ? total : 0),
            'onlineTotal': FieldValue.increment(channel == 'online' ? total : 0),
          },
          SetOptions(merge: true),
        );
        trx.set(
          monthlyRef,
          {
            'salesTotal': FieldValue.increment(total),
            'ordersCount': FieldValue.increment(1),
            'dineInTotal': FieldValue.increment(channel == 'dine-in' ? total : 0),
            'onlineTotal': FieldValue.increment(channel == 'online' ? total : 0),
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  Future<void> addItemsToOrder({
    required String orderId,
    required List<OrderItem> items,
    bool allowClosedOrders = false,
  }) async {
    if (items.isEmpty) {
      return;
    }

    final doc = _db.collection('orders').doc(orderId);
    await _db.runTransaction((trx) async {
      final snapshot = await trx.get(doc);
      if (!snapshot.exists) {
        throw StateError('El pedido no existe');
      }
      final data = snapshot.data()!;
      final status = data['status'] as String? ?? 'open';
      if (!allowClosedOrders && status != 'open') {
        throw StateError('El pedido ya no se puede modificar');
      }

      final rawItems = (data['items'] as List?) ?? const [];
      final currentItems = rawItems
          .map((dynamic item) => OrderItem.fromMap(
                Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
              ))
          .toList();

      final updatedItems = List<OrderItem>.from(currentItems);
      for (final item in items) {
        final index = updatedItems
            .indexWhere((element) => element.menuItemId == item.menuItemId);
        if (index == -1) {
          updatedItems.add(item);
        } else {
          final existing = updatedItems[index];
          updatedItems[index] = existing.copyWith(qty: existing.qty + item.qty);
        }
      }

      final updatedTotal = updatedItems
          .fold<double>(0, (total, element) => total + element.subtotal);

      trx.update(doc, {
        'items': updatedItems.map((item) => item.toMap()).toList(),
        'total': updatedTotal,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateOrderItemQuantity({
    required String orderId,
    required String menuItemId,
    required int quantity,
    bool allowClosedOrders = false,
  }) async {
    final doc = _db.collection('orders').doc(orderId);
    await _db.runTransaction((trx) async {
      final snapshot = await trx.get(doc);
      if (!snapshot.exists) {
        throw StateError('El pedido no existe');
      }
      final data = snapshot.data()!;
      final status = data['status'] as String? ?? 'open';
      if (!allowClosedOrders && status != 'open') {
        throw StateError('El pedido ya no se puede modificar');
      }

      final rawItems = (data['items'] as List?) ?? const [];
      final currentItems = rawItems
          .map((dynamic item) => OrderItem.fromMap(
                Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
              ))
          .toList();

      final index = currentItems
          .indexWhere((element) => element.menuItemId == menuItemId);
      if (index == -1) {
        throw StateError('El producto no existe en el pedido');
      }

      if (quantity <= 0) {
        currentItems.removeAt(index);
      } else {
        currentItems[index] = currentItems[index].copyWith(qty: quantity);
      }

      final updatedTotal = currentItems
          .fold<double>(0, (total, element) => total + element.subtotal);

      trx.update(doc, {
        'items': currentItems.map((item) => item.toMap()).toList(),
        'total': updatedTotal,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
