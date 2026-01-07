import '../Database/app_database.dart';
import '../Views/Auth/auth_storage.dart';
import '../utils/password_utils.dart';

class AuthController {
  // Singleton pattern
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;
  AuthController._internal();

  static AuthController get instance => _instance;

  Future<User?> login(String username, String password) async {
    // Mã hóa mật khẩu trước khi gửi xuống DB
    final hashedPassword = PasswordUtils.hash(password);

    final user = await db.login(username, hashedPassword);

    if (user != null) {
      currentUserId = user.id;
      await AuthStorage.saveUserId(user.id);
    }

    return user;
  }

  Future<User?> register({
    required String username,
    required String password,
    String? email,
  }) async {
    // Mã hóa mật khẩu
    final hashedPassword = PasswordUtils.hash(password);

    // Gọi DB đăng ký
    final user = await db.register(username, hashedPassword, email: email);

    // Nếu đăng ký thành công, tự động đăng nhập (tùy nghiệp vụ, ở đây làm đơn giản là trả về user để UI xử lý)
    return user;
  }

  Future<void> logout() async {
    await AuthStorage.logout();
    currentUserId = null;
  }
}
