class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory CategoryModel.fromMap(String id, Map<String, dynamic> data) {
    return CategoryModel(
      id: id,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : 'Sin nombre',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
}
