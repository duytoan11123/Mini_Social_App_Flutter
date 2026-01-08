import 'user_model.dart';

class PostModel {
  final String id;
  final String imageUrl;
  final String? caption;
  final int likes;
  final UserModel? author;
  final DateTime? createdAt;

  PostModel({
    required this.id,
    required this.imageUrl,
    this.caption,
    this.likes = 0,
    this.author,
    this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? json['_id'],
      imageUrl: json['imageUrl'] ?? '',
      caption: json['caption'],
      likes: (json['likes'] is int)
          ? json['likes']
          : (int.tryParse(json['likes']?.toString() ?? '0') ?? 0),
      author: json['author'] != null && json['author'] is Map<String, dynamic>
          ? UserModel.fromJson(json['author'])
          : null, // Handle if author is just ID string
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}
