import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/restaurant_table.dart';
import 'menu_screen.dart';


class TableSelectScreen extends StatelessWidget {
const TableSelectScreen({super.key});


@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text('Mesas')),
body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
stream: FirebaseFirestore.instance.collection('tables').orderBy('number').snapshots(),
builder: (context, snap) {
if (!snap.hasData) return const Center(child: CircularProgressIndicator());
final tables = snap.data!.docs
.map((d) => RestaurantTable.fromMap(d.id, d.data()))
.toList();
return GridView.builder(
padding: const EdgeInsets.all(12),
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.1, mainAxisSpacing: 8, crossAxisSpacing: 8),
itemCount: tables.length,
itemBuilder: (_, i) {
final t = tables[i];
final color = switch (t.status) { 'free' => Colors.green, 'occupied' => Colors.orange, _ => Colors.grey };
return InkWell(
onTap: () {
Navigator.of(context).push(MaterialPageRoute(
builder: (_) => MenuScreen(tableId: t.id),
));
},
child: Card(
child: Center(
child: Column(mainAxisSize: MainAxisSize.min, children: [
Text('Mesa ${t.number}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
const SizedBox(height: 6),
Chip(label: Text(t.status), backgroundColor: color.withOpacity(.15)),
]),
),
),
);
},
);
},
),
floatingActionButton: FloatingActionButton.extended(
onPressed: () {
// pedido online (sin mesa)
Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MenuScreen()));
},
label: const Text('Pedido online'),
icon: const Icon(Icons.shopping_bag_outlined),
),
);
}
}