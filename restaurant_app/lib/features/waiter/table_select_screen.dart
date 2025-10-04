import 'package:cloud_firestore/cloud_firestore.dart';
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
        stream: FirebaseFirestore.instance
            .collection('tables')
            .orderBy('number')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tables = snapshot.data!.docs
              .map((doc) => RestaurantTable.fromMap(doc.id, doc.data()))
              .toList();
          if (tables.isEmpty) {
            return const Center(child: Text('Aún no hay mesas registradas.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.1,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              final Color color;
              switch (table.status) {
                case 'free':
                  color = Colors.green;
                  break;
                case 'occupied':
                  color = Colors.orange;
                  break;
                case 'reserved':
                  color = Colors.blueAccent;
                  break;
                default:
                  color = Colors.grey;
              }
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MenuScreen(tableId: table.id),
                    ),
                  );
                },
                child: Card(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mesa ${table.number}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Chip(
                          label: Text(table.status),
                          backgroundColor: color.withOpacity(.15),
                          side: BorderSide(color: color.withOpacity(.6)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MenuScreen()),
          );
        },
        label: const Text('Pedido online'),
        icon: const Icon(Icons.shopping_bag_outlined),
      ),
    );
  }
}
