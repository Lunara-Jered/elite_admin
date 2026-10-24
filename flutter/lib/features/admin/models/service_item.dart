class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.unit,
    this.imageUrl,
    this.imagePath,
  });

  final String id;
  final String name;
  final String description;
  final num price;
  final String unit;
  final String? imageUrl;
  final String? imagePath;

  factory ServiceItem.fromMap(Map<String, dynamic> data) {
    return ServiceItem(
      id: data['id'].toString(),
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: data['price'] as num? ?? 0,
      unit: data['unit'] as String? ?? 'forfait',
      imageUrl: data['image_url'] as String?,
      imagePath: data['image_path'] as String?,
    );
  }
}