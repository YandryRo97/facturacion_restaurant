import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.unitPrice,
    required this.qty,
  });

  final String menuItemId;
  final String name;
  final double unitPrice;
  final int qty;

  double get subtotal => unitPrice * qty;

  OrderItem copyWith({
    String? menuItemId,
    String? name,
    double? unitPrice,
    int? qty,
  }) {
    return OrderItem(
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      qty: qty ?? this.qty,
    );
  }

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      menuItemId: data['menuItemId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0,
      qty: (data['qty'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'unitPrice': unitPrice,
      'qty': qty,
      'subtotal': subtotal,
    };
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.channel,
    required this.items,
    required this.total,
    required this.status,
    required this.waiterId,
    required this.createdAt,
    this.tableNumber,
    this.tableId,
    this.closedAt,
    this.paymentMethod,
  });

  final String id;
  final int orderNumber;
  final String? tableId;
  final int? tableNumber;
  final String channel;
  final List<OrderItem> items;
  final double total;
  final String status;
  final String waiterId;
  final DateTime createdAt;
  final DateTime? closedAt;
  final String? paymentMethod;

  factory OrderModel.fromMap(String id, Map<String, dynamic> data) {
    final rawItems = (data['items'] as List?) ?? const [];
    final items = rawItems
        .map((dynamic item) {
          final map = Map<String, dynamic>.from(item as Map<dynamic, dynamic>);
          return OrderItem.fromMap(map);
        })
        .toList();
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final closedAt = (data['closedAt'] as Timestamp?)?.toDate();
    return OrderModel(
      id: id,
      orderNumber: (data['orderNumber'] as num?)?.toInt() ?? 0,
      tableId: data['tableId'] as String?,
      tableNumber: (data['tableNumber'] as num?)?.toInt(),
      channel: data['channel'] as String? ?? 'dine-in',
      items: items,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      status: data['status'] as String? ?? 'open',
      waiterId: data['waiterId'] as String? ?? '',
      createdAt: createdAt,
      closedAt: closedAt,
      paymentMethod: data['paymentMethod'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'channel': channel,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status,
      'waiterId': waiterId,
      'createdAt': Timestamp.fromDate(createdAt),
      if (closedAt != null) 'closedAt': Timestamp.fromDate(closedAt!),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
    };
  }
}
