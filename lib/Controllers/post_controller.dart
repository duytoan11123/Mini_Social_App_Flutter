import 'dart:async';
import '../Models/post_model.dart';
import '../Services/api_service.dart';
import 'auth_controller.dart'; // Import AuthController

class PostController {
  static final PostController _instance = PostController._internal();
  factory PostController() => _instance;
  PostController._internal();

  static PostController get instance => _instance;

  final ApiService _api = ApiService();

  // StreamController for broadcasting post updates
  final _postsController = StreamController<List<PostModel>>.broadcast();
  Stream<List<PostModel>> get postsStream => _postsController.stream;

  // Cached posts
  List<PostModel> _posts = [];

  /// Fetch posts from API
  Future<void> fetchPosts() async {
    final posts = await _api.getPosts();
    _posts = posts;
    _postsController.add(_posts);
  }

  /// Tạo bài viết mới
  Future<void> createPost(String imageUrl, String caption) async {
    final currentUser = AuthController.instance.currentUser;
    if (currentUser == null) return;

    final newPost = await _api.createPost(currentUser.id, imageUrl, caption);
    _posts.insert(0, newPost);
    _postsController.add(_posts);
  }

  /// Xóa bài viết
  Future<void> deletePost(String postId) async {
    await _api.deletePost(postId);
    _posts.removeWhere((p) => p.id == postId);
    _postsController.add(_posts);
  }

  /// Cập nhật nội dung bài viết
  Future<void> updatePost(String postId, String newCaption) async {
    final updatedPost = await _api.updatePost(postId, newCaption);
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      _posts[index] = updatedPost;
      _postsController.add(_posts);
    }
  }

  /// Kiểm tra user đã like bài viết chưa
  Future<bool> hasLiked(String postId) async {
    final currentUser = AuthController.instance.currentUser;
    if (currentUser == null) return false;

    try {
      return await _api.hasLiked(postId, currentUser.id);
    } catch (e) {
      print("[PostController] hasLiked error: $e");
      return false;
    }
  }

  /// Toggle like
  Future<void> toggleLike(String postId) async {
    final currentUser = AuthController.instance.currentUser;
    if (currentUser == null) return;

    await _api.toggleLike(postId, currentUser.id);
    // Refresh posts to get new like count
    fetchPosts();
  }

  /// Clear all posts (e.g. on logout)
  void clear() {
    _posts = [];
    _postsController.add(_posts);
  }
}
