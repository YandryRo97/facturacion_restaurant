import 'package:cloud_firestore/cloud_firestore.dart';
State<MenuScreen> createState() => _MenuScreenState();
}


class _MenuScreenState extends State<MenuScreen> {
final List<OrderItem> cart = [];


void _add(MenuItemModel m) {
final idx = cart.indexWhere((e) => e.menuItemId == m.id);
setState(() {
if (idx == -1) {
cart.add(OrderItem(menuItemId: m.id, name: m.name, unitPrice: m.price, qty: 1));
} else {
final current = cart[idx];
cart[idx] = OrderItem(menuItemId: current.menuItemId, name: current.name, unitPrice: current.unitPrice, qty: current.qty + 1);
}
});
}


@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: Text(widget.tableId == null ? 'Menú (online)' : 'Menú (mesa)')),
body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
stream: FirebaseFirestore.instance.collection('menu_items').where('isAvailable', isEqualTo: true).snapshots(),
builder: (context, snap) {
if (!snap.hasData) return const Center(child: CircularProgressIndicator());
final items = snap.data!.docs.map((d) => MenuItemModel.fromMap(d.id, d.data())).toList();
return ListView.builder(
itemCount: items.length,
itemBuilder: (_, i) {
final m = items[i];
return ListTile(
title: Text(m.name),
subtitle: Text(m.category),
trailing: Text('\$${m.price.toStringAsFixed(2)}'),
onTap: () => _add(m),
);
},
);
},
),
floatingActionButton: FloatingActionButton.extended(
onPressed: cart.isEmpty
? null
: () async {
final user = FirebaseAuth.instance.currentUser!;
final repo = OrderRepository();
final id = await repo.createOrder(
waiterId: user.uid,
tableId: widget.tableId,
channel: widget.tableId == null ? 'online' : 'dine-in',
items: cart,
);
if (!mounted) return;
Navigator.of(context).push(MaterialPageRoute(builder: (_) => CartScreen(orderId: id)));
},
label: const Text('Crear pedido'),
icon: const Icon(Icons.shopping_cart_checkout),
),
);
}
}