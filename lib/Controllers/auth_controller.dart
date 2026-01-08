import '../Models/user_model.dart';
import 'post_controller.dart';
import '../Services/api_service.dart';
import '../Views/Auth/auth_storage.dart';

// Global variable removed/commented out to favor instance variable usage
// UserModel? currentUser;

class AuthController {
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;
  AuthController._internal();

  static AuthController get instance => _instance;

  final ApiService _api = ApiService();

  UserModel? currentUser; // Instance variable

  Future<UserModel> login(String username, String password) async {
    try {
      final user = await _api.login(username, password);
      currentUser = user;
      return user;
    } catch (e) {
      print("Login error: $e");
      rethrow;
    }
  }

  Future<UserModel> register({
    required String username,
    required String password,
    String? email,
  }) async {
    try {
      final user = await _api.register(username, password, email ?? "");
      currentUser = user;
      return user;
    } catch (e) {
      print("Register error: $e");
      rethrow;
    }
  }

  Future<void> logout() async {
    currentUser = null;
    await AuthStorage.logout();
    PostController.instance.clear();
  }
}
