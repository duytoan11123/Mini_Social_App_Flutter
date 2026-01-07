import 'package:drift/drift.dart';
import '../Database/app_database.dart';

class PostController {
  static final PostController _instance = PostController._internal();
  static PostController get instance => _instance;

  PostController._internal();

  /// Tạo bài viết mới
  Future<int> createPost(String imageUrl, String? caption) async {
    if (currentUserId == null) throw Exception("User not logged in");

    final entry = PostsCompanion(
      authorId: Value(currentUserId!),
      imageUrl: Value(imageUrl),
      caption: Value(caption),
    );
    return await db.insertPost(entry);
  }

  /// Xóa bài viết
  Future<void> deletePost(int postId) async {
    await db.deletePost(postId);
  }

  /// Cập nhật nội dung bài viết
  Future<void> updatePost(Post post, String newCaption) async {
    final updatedPost = post.copyWith(caption: Value(newCaption));
    await db.updatePost(updatedPost);
  }

  /// Kiểm tra user đã like bài viết chưa
  Future<bool> hasLiked(int postId) async {
    if (currentUserId == null) return false;
    return await db.hasUserLikedPost(postId, currentUserId!);
  }

  /// Toggle like
  Future<void> toggleLike(int postId) async {
    if (currentUserId == null) throw Exception("User not logged in");
    await db.togglePostLike(postId, currentUserId!);
  }

  /// Watch danh sách bài viết kèm user
  Stream<List<PostWithUser>> watchPostsWithUsers() {
    return db.watchPostsWithUsers();
  }
}
