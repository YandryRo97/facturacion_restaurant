class OrderItem {
final String? tableId;
final String channel; // dine-in | online
final List<OrderItem> items;
final double total;
final String status; // open|preparing|served|paid|cancelled
final String waiterId;
final DateTime createdAt;
final DateTime? closedAt;
final String? paymentMethod;


OrderModel({
required this.id,
required this.orderNumber,
required this.channel,
required this.items,
required this.total,
required this.status,
required this.waiterId,
required this.createdAt,
this.tableId,
this.closedAt,
this.paymentMethod,
});


factory OrderModel.fromMap(String id, Map<String, dynamic> data) {
final items = (data['items'] as List? ?? []).cast<Map<String, dynamic>>()
.map((e) => OrderItem.fromMap(e)).toList();
return OrderModel(
id: id,
orderNumber: data['orderNumber'] ?? 0,
tableId: data['tableId'],
channel: data['channel'] ?? 'dine-in',
items: items,
total: (data['total'] ?? 0).toDouble(),
status: data['status'] ?? 'open',
waiterId: data['waiterId'] ?? '',
createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
paymentMethod: data['paymentMethod'],
);
}


Map<String, dynamic> toMap() => {
'orderNumber': orderNumber,
'tableId': tableId,
'channel': channel,
'items': items.map((e) => e.toMap()).toList(),
'total': total,
'status': status,
'waiterId': waiterId,
'createdAt': FieldValue.serverTimestamp(),
'closedAt': closedAt,
'paymentMethod': paymentMethod,
};
}