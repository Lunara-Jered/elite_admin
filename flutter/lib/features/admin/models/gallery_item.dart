class GalleryItem {
  const GalleryItem({
    required this.id,
    required this.category,
    required this.caption,
    required this.imageUrl,
    required this.imagePath,
  });

  final String id;
  final String category;
  final String caption;
  final String imageUrl;
  final String imagePath;

  factory GalleryItem.fromMap(Map<String, dynamic> data) {
    return GalleryItem(
      id: data['id'].toString(),
      category: data['category'] as String? ?? '',
      caption: data['caption'] as String? ?? '',
      imageUrl: data['image_url'] as String? ?? '',
      imagePath: data['image_path'] as String? ?? '',
    );
  }
}