import 'package:flutter/material.dart';
import 'Views/Auth/login_screen.dart';
import 'Views/Post/news_feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check login status via AuthController (which uses ApiService/SharedPreferences)
  // We need to implement a checkLogin or similar if not exists, or just check generic Token/User
  // For now, let's assume AuthController has a method or we can check currentUser
  // But wait, AudioController is singleton.
  // Actually, standard way is to generic a splash screen or wait.
  // For simplicity, let's attempt to restore session.

  // Note: We haven't implemented "restore session" in AuthController yet,
  // but we can add it or just start at Login for now to be safe until we add token storage.
  // However, `AuthStorage` was local. `ApiService` might need a token.
  // Let's rely on AuthController to handle this in a future update or just show Login.
  // If we want to keep it simple:

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    // In a real app, verify token. For now, we might not have persistence set up with API yet
    // unless existing AuthStorage tokens are valid?
    // The previous AuthStorage was for SQLite IDs.
    // So we likely need to login again.
    // Let's check if AuthController has a user.
    // Since app just started, it's null.
    // So we defaults to LoginScreen.

    // Future: Implement token storage and validation in AuthController.
    setState(() {
      _isLoading = false;
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _isLoggedIn ? const NewsFeedScreen() : const LoginScreen(),
    );
  }
}
