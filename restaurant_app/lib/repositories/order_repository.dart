import 'package:cloud_firestore/cloud_firestore.dart';


Future<int> _nextOrderNumber() async {
// Simple: consulta el mayor `orderNumber` de los últimos N y +1 (para demo). Para producción, usar un contador transaccional.
final snap = await _db.collection('orders').orderBy('orderNumber', descending: true).limit(1).get();
final last = snap.docs.isNotEmpty ? (snap.docs.first.data()['orderNumber'] ?? 0) as int : 0;
return last + 1;
}


Future<String> createOrder({
required String waiterId,
String? tableId,
required String channel,
required List<OrderItem> items,
}) async {
final orderNumber = await _nextOrderNumber();
final total = items.fold<double>(0, (p, e) => p + e.subtotal);
final doc = _db.collection('orders').doc();
await doc.set({
'orderNumber': orderNumber,
'tableId': tableId,
'channel': channel,
'items': items.map((e) => e.toMap()).toList(),
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


Future<void> updateOrderStatus({required String orderId, required String status, String? paymentMethod}) async {
final doc = _db.collection('orders').doc(orderId);
await _db.runTransaction((trx) async {
final snap = await trx.get(doc);
final data = snap.data()!;
trx.update(doc, {
'status': status,
if (status == 'paid') 'closedAt': FieldValue.serverTimestamp(),
if (paymentMethod != null) 'paymentMethod': paymentMethod,
});
// Si se paga → actualizar summaries
if (status == 'paid') {
final total = (data['total'] ?? 0).toDouble();
final channel = data['channel'] as String? ?? 'dine-in';
final now = Timestamp.now().toDate();
final dayId = '${now.year.toString().padLeft(4,'0')}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
final monthId = '${now.year.toString().padLeft(4,'0')}-${now.month.toString().padLeft(2,'0')}';
final dailyRef = _db.collection('summaries').doc('daily').collection('docs').doc(dayId);
final monthlyRef = _db.collection('summaries').doc('monthly').collection('docs').doc(monthId);
// upsert
trx.set(dailyRef, {
'salesTotal': FieldValue.increment(total),
'ordersCount': FieldValue.increment(1),
'dineInTotal': FieldValue.increment(channel == 'dine-in' ? total : 0),
'onlineTotal': FieldValue.increment(channel == 'online' ? total : 0),
}, SetOptions(merge: true));
trx.set(monthlyRef, {
'salesTotal': FieldValue.increment(total),
'ordersCount': FieldValue.increment(1),
'dineInTotal': FieldValue.increment(channel == 'dine-in' ? total : 0),
'onlineTotal': FieldValue.increment(channel == 'online' ? total : 0),
}, SetOptions(merge: true));
}
});
}
}