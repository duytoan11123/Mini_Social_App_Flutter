import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../Database/app_database.dart';
import '../Views/Auth/auth_storage.dart';

class ProfileController {
  // Singleton pattern
  static final ProfileController instance = ProfileController._();
  ProfileController._();

  final _picker = ImagePicker();

  // 1. Logic chọn ảnh từ thư viện
  Future<File?> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print("Lỗi chọn ảnh: $e");
      return null;
    }
  }

  // 2. Logic lưu thông tin User xuống DB
  Future<bool> updateUserProfile({
    required User currentUser,
    required String newName,
    required String newBio,
    File? newAvatarFile,
  }) async {
    // [BỔ SUNG] Validate dữ liệu đầu vào
    if (newName.trim().isEmpty) {
      print("Tên không được để trống");
      return false;
    }

    try {
      // Logic xác định đường dẫn ảnh
      String? finalAvatarUrl;
      if (newAvatarFile != null) {
        finalAvatarUrl = newAvatarFile.path;
      } else {
        finalAvatarUrl = currentUser.avatarUrl;
      }

      User updatedUser = User(
        id: currentUser.id,
        userName: currentUser.userName,
        password: currentUser.password,
        avatarUrl: finalAvatarUrl,
        fullName: newName.trim(),
        bio: newBio.trim(),
      );

      await db.updateUser(updatedUser);
      return true; // Thành công
    } catch (e) {
      print("Lỗi update profile: $e");
      return false; // Thất bại
    }
  }

  // --- LOGIC CHO PROFILE & USER PROFILE ---

  // 3. Lấy thông tin User theo ID
  Future<User?> getUserById(int id) async {
    return await db.getUserById(id);
  }

  // 4. Lấy danh sách bài viết của User
  Future<List<Post>> getUserPosts(int userId) async {
    return await db.getPostsByUserId(userId);
  }

  // 5. Kiểm tra trạng thái Follow
  // [QUAN TRỌNG] Đổi tên thành checkIsFollowing để khớp với UserProfileScreen
  Future<bool> checkIsFollowing(int currentUserId, int targetUserId) async {
    return await db.isFollowing(currentUserId, targetUserId);
  }

  // 6. Toggle Follow (Bấm theo dõi/hủy theo dõi)
  Future<void> toggleFollow(int currentUserId, int targetUserId) async {
    await db.toggleFollow(currentUserId, targetUserId);
  }

  // 7. Stream đếm số lượng (Reactive - Tự động cập nhật UI)
  Stream<int> watchFollowersCount(int userId) {
    // Đảm bảo trong AppDatabase bạn đã viết hàm watchFollowersCount trả về Stream<int>
    return db.watchFollowersCount(userId);
  }

  Stream<int> watchFollowingCount(int userId) {
    // Đảm bảo trong AppDatabase bạn đã viết hàm watchFollowingCount trả về Stream<int>
    return db.watchFollowingCount(userId);
  }

  // 8. Logout
  Future<void> logout() async {
    await AuthStorage.logout();
    currentUserId = null;
  }
}
