import 'package:flutter/material.dart';
import 'create_post_modal.dart';
import 'post_list.dart';
import '../Login/auth_storage.dart';
import '../Login/login_screen.dart';
import '../Database/app_database.dart';
import '../Profile/profile_screen.dart';
import '../Search/search_screen.dart';

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
          // Thêm nút tìm kiếm
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Tìm kiếm',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          InkWell(
            onTap: () {
              // Chuyển sang trang Profile khi bấm vào
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  // Hình tròn Avatar
                  CircleAvatar(
                    radius: 16, // Kích thước nhỏ vừa phải trên AppBar
                    backgroundColor: Colors.grey.shade300,
                    // Nếu sau này có ảnh thì dùng NetworkImage, giờ dùng icon tạm
                    child: const Icon(
                      Icons.person,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
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
