class MenuItemModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final bool isAvailable;
  final String? imageUrl;
  final String? description;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.isAvailable,
    this.imageUrl,
    this.description,
  });

  factory MenuItemModel.fromMap(String id, Map<String, dynamic> data) {
    return MenuItemModel(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'General',
      price: (data['price'] ?? 0).toDouble(),
      isAvailable: data['isAvailable'] ?? true,
      imageUrl: data['imageUrl'] as String?,
      description: data['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
      if (description != null && description!.isNotEmpty) 'description': description,
    };
  }
}
