import '../Models/comment_model.dart';
import '../Services/api_service.dart';
import 'auth_controller.dart';

class CommentController {
  static final CommentController _instance = CommentController._internal();
  factory CommentController() => _instance;
  CommentController._internal();

  static CommentController get instance => _instance;

  final ApiService _api = ApiService();

  Future<void> addComment(
    String postId,
    String content, {
    String? parentId,
  }) async {
    if (AuthController.instance.currentUser == null) {
      throw Exception("User not logged in");
    }
    await _api.addComment(
      postId,
      AuthController.instance.currentUser!.id,
      content,
      parentId: parentId,
    );
  }

  Future<int> getCommentCount(String postId) async {
    final comments = await _api.getComments(postId);
    return comments.length;
  }

  Future<List<CommentModel>> getRecentComments(
    String postId, {
    int limit = 100,
  }) async {
    final currentUser = AuthController.instance.currentUser;
    final comments = await _api.getComments(postId, userId: currentUser?.id);
    return comments;
  }

  Future<bool> toggleLike(String commentId) async {
    final currentUser = AuthController.instance.currentUser;
    if (currentUser == null) return false;

    return await _api.toggleCommentLike(commentId, currentUser.id);
  }
}
