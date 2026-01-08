import 'dart:io';
import '../Models/user_model.dart';
import '../Models/post_model.dart';
import '../Services/api_service.dart';
import 'auth_controller.dart';

class UserController {
  static final UserController _instance = UserController._internal();
  static UserController get instance => _instance;

  UserController._internal();

  final ApiService _api = ApiService();

  /// Lấy thông tin User theo ID
  Future<UserModel?> getUserById(String userId) async {
    // API endpoint might be needed for get user by ID if not just 'me'
    // For now assuming we can fetch user details.
    // If API doesn't have specific get-user-by-id, we might rely on what we have.
    // The previous implementation used DB.
    // Let's assume we implement getUserProfile in ApiService later or now.
    return await _api.getUserProfile(userId);
  }

  /// Lấy danh sách bài viết của User
  Future<List<PostModel>> getPostsByUserId(String userId) async {
    // We can filter posts by user.
    // Assuming API has endpoint or filter.
    // Making a specific API call for this.
    final posts = await _api.getPosts(userId: userId);
    return posts;
  }

  /// Tìm kiếm User theo từ khóa
  Future<List<UserModel>> searchUsers(String keyword) async {
    if (keyword.isEmpty) return [];
    return await _api.searchUsers(keyword);
  }

  /// Watch số lượng Followers - Turning into Future for API
  Stream<int> watchFollowersCount(String userId) async* {
    // Polling or just one-time fetch for now.
    // API doesn't support socket/stream yet.
    // Fetch once and yield.
    final user = await _api.getUserProfile(userId);
    if (user != null) {
      yield user.followersCount;
    } else {
      yield 0;
    }
  }

  /// Watch số lượng Following
  Stream<int> watchFollowingCount(String userId) async* {
    final user = await _api.getUserProfile(userId);
    if (user != null) {
      yield user.followingCount;
    } else {
      yield 0;
    }
  }

  /// Check if following
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    // We pass requesterId to getProfile to get the isFollowing status
    final user = await _api.getUserProfile(
      targetUserId,
      requesterId: currentUserId,
    );
    return user?.isFollowing ?? false;
  }

  Future<String> uploadAvatar(File file) async {
    return await _api.uploadImage(file);
  }

  Future<UserModel> updateProfile(
    String userId, {
    String? fullName,
    String? bio,
    String? avatarUrl,
  }) async {
    return await _api.updateProfile(
      userId,
      fullName: fullName,
      bio: bio,
      avatarUrl: avatarUrl,
    );
  }

  /// Toggle follow
  Future<void> toggleFollow(String targetUserId) async {
    final currentUser = AuthController.instance.currentUser;
    if (currentUser == null) return;
    await _api.toggleFollowUser(targetUserId, currentUser.id);
  }
}
