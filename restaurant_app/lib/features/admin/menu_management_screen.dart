import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/menu_item.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final NumberFormat _currencyFormat = NumberFormat.simpleCurrency(name: 'USD');

  Future<void> _openItemForm(
    BuildContext context, {
    MenuItemModel? item,
    String? presetCategory,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final categoryCtrl = TextEditingController(
      text: item?.category ?? presetCategory ?? 'Hamburguesas',
    );
    final priceCtrl = TextEditingController(
      text: item != null ? item.price.toStringAsFixed(2) : '',
    );
    final descriptionCtrl = TextEditingController(text: item?.description ?? '');
    bool isAvailable = item?.isAvailable ?? true;
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      item == null ? 'Nuevo producto' : 'Editar producto',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionCtrl,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Descripción'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Precio (USD)'),
                      validator: (value) {
                        final normalized = value?.replaceAll(',', '.');
                        final parsed = double.tryParse(normalized ?? '');
                        if (parsed == null) {
                          return 'Ingresa un precio válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: isAvailable,
                      title: const Text('Disponible'),
                      onChanged: (value) => setModalState(() {
                        isAvailable = value;
                      }),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final normalizedPrice =
                            priceCtrl.text.replaceAll(',', '.');
                        final price = double.parse(normalizedPrice);
                        final description = descriptionCtrl.text.trim();
                        final data = {
                          'name': nameCtrl.text.trim(),
                          'category': categoryCtrl.text.trim(),
                          'price': price,
                          'description':
                              description.isEmpty ? null : description,
                          'isAvailable': isAvailable,
                          'updatedAt': FieldValue.serverTimestamp(),
                        };
                        final collection = FirebaseFirestore.instance
                            .collection('menu_items');
                        try {
                          if (item == null) {
                            await collection.add({
                              ...data,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Producto creado correctamente.'),
                              ),
                            );
                          } else {
                            await collection.doc(item.id).update(data);
                            messenger.showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Cambios guardados correctamente.'),
                              ),
                            );
                          }
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        } on FirebaseException catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                e.message ?? 'No se pudo guardar el producto.',
                              ),
                            ),
                          );
                        }
                      },
                      child:
                          Text(item == null ? 'Crear producto' : 'Guardar cambios'),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('menu_items')
            .orderBy('category')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!.docs
              .map((doc) => MenuItemModel.fromMap(doc.id, doc.data()))
              .toList();
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.restaurant_menu, size: 72, color: Colors.black45),
                  const SizedBox(height: 16),
                  const Text(
                    'Aún no hay productos en el catálogo.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _openItemForm(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar producto'),
                  ),
                ],
              ),
            );
          }

          final grouped = <String, List<MenuItemModel>>{};
          for (final item in items) {
            grouped.putIfAbsent(item.category, () => []).add(item);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.map((entry) {
              final category = entry.key;
              final products = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_dining, color: Colors.black87),
                          const SizedBox(width: 8),
                          Text(
                            category,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _openItemForm(
                              context,
                              presetCategory: category,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      ...products.map((product) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(product.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.description?.isNotEmpty == true
                                  ? product.description!
                                  : 'Sin descripción'),
                              const SizedBox(height: 4),
                              Text(product.isAvailable ? 'Disponible' : 'Agotado'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currencyFormat.format(product.price),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _openItemForm(context, item: product),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () => _openItemForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
      ),
    );
  }
}
