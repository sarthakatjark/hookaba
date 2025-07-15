class LibraryItemModel {
  final String imageUrl;
  final String userId;
  final DateTime createdAt;

  LibraryItemModel({
    required this.imageUrl,
    required this.userId,
    required this.createdAt,
  });

  factory LibraryItemModel.fromJson(Map<String, dynamic> json) {
    return LibraryItemModel(
      imageUrl: json['url'] ?? '',
      userId: json['user_id'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
} 