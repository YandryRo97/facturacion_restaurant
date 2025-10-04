import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class CartScreen extends StatelessWidget {
final String orderId;
const CartScreen({super.key, required this.orderId});


@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: Text('Pedido #$orderId')),
body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
builder: (context, snap) {
if (!snap.hasData) return const Center(child: CircularProgressIndicator());
final data = snap.data!.data()!;
final items = (data['items'] as List).cast<Map<String, dynamic>>();
final total = (data['total'] ?? 0).toDouble();
final status = data['status'] as String;
return Column(
children: [
Expanded(
child: ListView.builder(
itemCount: items.length,
itemBuilder: (_, i) => ListTile(
title: Text(items[i]['name']),
trailing: Text('${items[i]['qty']} x \$${(items[i]['unitPrice'] as num).toStringAsFixed(2)}'),
subtitle: Text('Subtotal: \$${(items[i]['subtotal'] as num).toStringAsFixed(2)}'),
),
),
),
Padding(
padding: const EdgeInsets.all(16),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text('Estado: $status'),
Text('Total: \$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
],
),
)
],
);
},
),
);
}
}