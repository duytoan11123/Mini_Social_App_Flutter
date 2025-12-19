import 'package:flutter/material.dart';
import 'create_post_modal.dart';
import 'post_list.dart';
import '../Login/auth_storage.dart';
import '../Login/login_screen.dart';
import '../Database/app_database.dart';

class NewsFeedScreen extends StatelessWidget {
  const NewsFeedScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Social App",
          style: TextStyle(fontFamily: 'Billabong', fontSize: 30),
        ),
        centerTitle: false,
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.favorite_border),
          ),

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthStorage.logout();
              currentUserId = null;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: PostListWidget(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Xử lý khi nhấn nút Đăng ảnh (mở màn hình tạo bài đăng mới)
          _showCreatePostModal(context);
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }

  void _showCreatePostModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext bc) {
        // Sử dụng Padding để đẩy nội dung lên khi bàn phím xuất hiện
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: CreatePostForm(),
        );
      },
    );
  }
}
