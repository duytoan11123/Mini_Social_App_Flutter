import '../Database/app_database.dart';

class UserController {
  static final UserController _instance = UserController._internal();
  static UserController get instance => _instance;

  UserController._internal();

  /// Lấy thông tin User theo ID
  Future<User?> getUserById(int userId) async {
    return await db.getUserById(userId);
  }

  /// Lấy danh sách bài viết của User
  Future<List<Post>> getPostsByUserId(int userId) async {
    return await db.getPostsByUserId(userId);
  }

  /// Tìm kiếm User theo từ khóa
  Future<List<User>> searchUsers(String keyword) async {
    return await db.searchUsers(keyword);
  }

  /// Watch số lượng Followers
  Stream<int> watchFollowersCount(int userId) {
    return db.watchFollowersCount(userId);
  }

  /// Watch số lượng Following
  Stream<int> watchFollowingCount(int userId) {
    return db.watchFollowingCount(userId);
  }

  /// Check if following
  Future<bool> isFollowing(int currentUserId, int targetUserId) async {
    return await db.isFollowing(currentUserId, targetUserId);
  }

  /// Toggle follow
  Future<void> toggleFollow(int currentUserId, int targetUserId) async {
    await db.toggleFollow(currentUserId, targetUserId);
  }
}
