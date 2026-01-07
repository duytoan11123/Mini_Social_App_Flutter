import 'package:flutter/material.dart';
import '../../Database/app_database.dart'; // Để dùng class Post, User, PostWithUser
import 'post_item.dart'; // Để dùng giao diện hiển thị bài viết

class PostDetailScreen extends StatelessWidget {
  final Post post;
  final User user;

  const PostDetailScreen({super.key, required this.post, required this.user});

  @override
  Widget build(BuildContext context) {
    // Tạo đối tượng PostWithUser để truyền vào PostItem
    // (Giả sử PostItem của bạn nhận vào một biến kiểu PostWithUser)
    final postWithUser = PostWithUser(post: post, user: user);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết bài viết"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        // Tái sử dụng PostItem từ trang NewsFeed
        child: PostItem(post: postWithUser),
      ),
    );
  }
}
