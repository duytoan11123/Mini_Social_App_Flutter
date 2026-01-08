import 'user_model.dart';

class CommentModel {
  final String id;
  final String content;
  final String postId;
  final DateTime? createdAt;
  final UserModel? user;
  final String? parentId; // For replies
  int likesCount;
  bool isLiked;

  CommentModel({
    required this.id,
    required this.content,
    required this.postId,
    this.createdAt,
    this.user,
    this.parentId,
    this.likesCount = 0,
    this.isLiked = false,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? json['_id'],
      content: json['content'] ?? '',
      postId: json['postId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'])
          : null,
      parentId: json['parentId'],
      likesCount: json['likesCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
    );
  }
}
