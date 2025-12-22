import 'package:flutter/material.dart';
import 'Database/app_database.dart';
import 'Login/login_screen.dart';
import 'Login/auth_storage.dart';
import 'NewsFeedScreen/news_feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDatabase();
  // await db.insertUser(
  //   UsersCompanion.insert(userName: 'admin', password: '123456'),
  // );
  final savedUserId = await AuthStorage.getUserId();
  currentUserId = savedUserId;
  runApp(MyApp(isLoggedIn: savedUserId != null));
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
