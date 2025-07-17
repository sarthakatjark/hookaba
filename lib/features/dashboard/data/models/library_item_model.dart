class LibraryItemModel {
  final String imageUrl;
  final String userId;
  final DateTime createdAt;
  final String type;
  final String category;

  LibraryItemModel({
    required this.imageUrl,
    required this.userId,
    required this.createdAt,
    required this.type,
    required this.category,
  });

  factory LibraryItemModel.fromJson(Map<String, dynamic> json) {
    return LibraryItemModel(
      imageUrl: json['url'] ?? '',
      userId: json['user_id'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      type: json['type'] ?? '',
      category: json['category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': imageUrl,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'type': type,
      'category': category,
    };
  }
} 