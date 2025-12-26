import 'package:flutter/material.dart';
import 'Database/app_database.dart';
import 'Login/login_screen.dart';
import 'Login/auth_storage.dart';
import 'NewsFeedScreen/news_feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDatabase();

  final savedUserId = await AuthStorage.getUserId();

  // Kiểm tra user còn tồn tại trong database không
  if (savedUserId != null) {
    final user = await db.getUserById(savedUserId);
    if (user != null) {
      currentUserId = savedUserId;
    } else {
      // User không còn tồn tại, xóa session cũ
      await AuthStorage.logout();
      currentUserId = null;
    }
  }

  runApp(MyApp(isLoggedIn: currentUserId != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const NewsFeedScreen() : const LoginScreen(),
    );
  }
}
