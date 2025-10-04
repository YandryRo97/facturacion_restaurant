import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/restaurant_table.dart';

class TableManagementScreen extends StatelessWidget {
  const TableManagementScreen({super.key});

  Future<void> _openForm(BuildContext context, {RestaurantTable? table}) async {
    final formKey = GlobalKey<FormState>();
    final numberCtrl = TextEditingController(text: table?.number.toString() ?? '');
    final seatsCtrl = TextEditingController(text: table?.seats.toString() ?? '4');
    String status = table?.status ?? 'free';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  table == null ? 'Registrar mesa' : 'Editar mesa',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: numberCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Número de mesa'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa un número';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: seatsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Capacidad (personas)'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa la capacidad';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(value: 'free', child: Text('Disponible')),
                    DropdownMenuItem(value: 'occupied', child: Text('Ocupada')),
                    DropdownMenuItem(value: 'reserved', child: Text('Reservada')),
                    DropdownMenuItem(value: 'cleaning', child: Text('En limpieza')),
                  ],
                  onChanged: (value) => status = value ?? 'free',
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final number = int.tryParse(numberCtrl.text.trim()) ?? 0;
                    final seats = int.tryParse(seatsCtrl.text.trim()) ?? 4;
                    final data = {
                      'number': number,
                      'seats': seats,
                      'status': status,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };
                    final tablesRef =
                        FirebaseFirestore.instance.collection('tables');
                    if (table == null) {
                      await tablesRef.add({
                        ...data,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    } else {
                      await tablesRef.doc(table.id).update(data);
                    }
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(table == null ? 'Guardar mesa' : 'Actualizar mesa'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.table_bar, size: 72, color: Colors.black45),
                  const SizedBox(height: 16),
                  const Text(
                    'Todavía no has registrado mesas.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _openForm(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar primera mesa'),
                  ),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                final color = _statusColor(table.status);
                return GestureDetector(
                  onTap: () => _openForm(context, table: table),
                  child: Card(
                    elevation: 4,
                    shadowColor: color.withOpacity(.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: color.withOpacity(.15),
                                child: Icon(Icons.table_bar, color: color),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openForm(context, table: table),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Mesa ${table.number}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text('Capacidad: ${table.seats} personas'),
                          const Spacer(),
                          Chip(
                            backgroundColor: color.withOpacity(.15),
                            side: BorderSide(color: color.withOpacity(.4)),
                            label: Text(
                              _statusLabel(table.status),
                              style: TextStyle(color: color.darken()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva mesa'),
      ),
    );
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
        return 'Desconocido';
    }
  }
}

extension _ColorUtils on Color {
  Color darken([double amount = .2]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
