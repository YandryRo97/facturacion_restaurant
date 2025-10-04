import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/restaurant_table.dart';
import 'menu_screen.dart';

class TableSelectScreen extends StatelessWidget {
  const TableSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    const Icon(Icons.table_bar, size: 32, color: Colors.black),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selecciona una mesa',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Visualiza disponibilidad en tiempo real'),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                          return const Center(
                            child: Text('Aún no hay mesas registradas.'),
                          );
                        }
                        return GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.2,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                          ),
                          itemCount: tables.length,
                          itemBuilder: (context, index) {
                            final table = tables[index];
                            final status = _statusLabel(table.status);
                            final color = _statusColor(table.status);
                            return InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MenuScreen(
                                      tableId: table.id,
                                      tableNumber: table.number,
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 6,
                                shadowColor: color.withOpacity(.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: color.withOpacity(.15),
                                            child: Icon(Icons.event_seat, color: color),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '#${table.number}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${table.seats} comensales',
                                        style: Theme.of(context).textTheme.labelLarge,
                                      ),
                                      const SizedBox(height: 6),
                                      Chip(
                                        backgroundColor: color.withOpacity(.18),
                                        side: BorderSide(
                                          color: color.withOpacity(.4),
                                        ),
                                        label: Text(
                                          status,
                                          style: TextStyle(
                                            color: color.darken(),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
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

Color _statusColor(String status) {
  switch (status) {
    case 'free':
      return const Color(0xFF4CAF50);
    case 'occupied':
      return const Color(0xFFFF7043);
    case 'reserved':
      return const Color(0xFF42A5F5);
    case 'cleaning':
      return const Color(0xFF8D6E63);
    default:
      return Colors.grey;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'free':
      return 'Disponible';
    case 'occupied':
      return 'Ocupada';
    case 'reserved':
      return 'Reservada';
    case 'cleaning':
      return 'En limpieza';
    default:
      return status;
  }
}

extension _ColorDarken on Color {
  Color darken([double amount = .2]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
