class MenuItemModel {
final String id;
final String name;
final String category;
final double price;
final bool isAvailable;
final String? imageUrl;


MenuItemModel({
required this.id,
required this.name,
required this.category,
required this.price,
required this.isAvailable,
this.imageUrl,
});


factory MenuItemModel.fromMap(String id, Map<String, dynamic> data) {
return MenuItemModel(
id: id,
name: data['name'] ?? '',
category: data['category'] ?? 'General',
price: (data['price'] ?? 0).toDouble(),
isAvailable: data['isAvailable'] ?? true,
imageUrl: data['imageUrl'],
);
}


Map<String, dynamic> toMap() => {
'name': name,
'category': category,
'price': price,
'isAvailable': isAvailable,
'imageUrl': imageUrl,
};
}