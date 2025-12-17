import 'package:flutter/material.dart';
import 'NewsFeedScreen/news_feed_screen.dart';
import 'Database/app_database.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDatabase();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instagram Feed Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1
        ),
      ),
      home: NewsFeedScreen(),
    );
  }
}

