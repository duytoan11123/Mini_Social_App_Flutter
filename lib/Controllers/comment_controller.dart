import 'package:drift/drift.dart';
import '../Database/app_database.dart';

class CommentController {
  static final CommentController _instance = CommentController._internal();
  static CommentController get instance => _instance;

  CommentController._internal();

  /// Thêm bình luận mới
  Future<void> addComment({
    required int postId,
    required int userId,
    required String content,
    String? imageUrl,
    int? parentId,
  }) async {
    await db.insertComment(
      CommentsCompanion(
        postId: Value(postId),
        userId: Value(userId),
        content: content.isNotEmpty ? Value(content) : const Value.absent(),
        imageUrl: imageUrl != null ? Value(imageUrl) : const Value.absent(),
        parentId: parentId != null ? Value(parentId) : const Value.absent(),
      ),
    );
  }

  /// Xóa bình luận
  Future<void> deleteComment(int commentId) async {
    await db.deleteComment(commentId);
  }

  /// Watch bình luận của bài viết
  Stream<List<CommentWithUser>> watchCommentsForPost(int postId) {
    return db.watchCommentsForPost(postId);
  }

  /// Watch các phản hồi (replies) cho bình luận
  Stream<List<CommentWithUser>> watchRepliesForComment(int commentId) {
    return db.watchRepliesForComment(commentId);
  }

  /// Toggle reaction
  Future<void> toggleReaction(
    int commentId,
    int userId,
    String reactionType,
  ) async {
    await db.toggleReaction(commentId, userId, reactionType);
  }

  /// Lấy reaction của user đối với comment
  Future<String?> getUserReaction(int commentId, int userId) async {
    return await db.getUserReaction(commentId, userId);
  }

  /// Watch tổng hợp reactions
  Stream<List<ReactionCount>> watchReactionsForComment(int commentId) {
    return db.watchReactionsForComment(commentId);
  }

  /// Get comment count
  Future<int> getCommentCount(int postId) async {
    return await db.getCommentCount(postId);
  }

  /// Get recent comments
  Future<List<CommentWithUser>> getRecentComments(
    int postId, {
    int limit = 2,
  }) async {
    return await db.getRecentComments(postId, limit: limit);
  }
}
