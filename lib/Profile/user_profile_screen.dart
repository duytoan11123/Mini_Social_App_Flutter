import 'dart:io';
import 'package:flutter/material.dart';
import '../Database/app_database.dart';
import '../main.dart'; // Chứa biến db
import '../NewsFeedScreen/post_detail_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final User user; // Nhận thông tin người dùng cần xem từ màn hình Search

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  List<Post> _userPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPosts();
  }

  // Load bài viết của người này
  Future<void> _loadUserPosts() async {
    // Gọi hàm lấy bài viết theo ID (Cần đảm bảo hàm này đã có trong AppDatabase)
    // Nếu chưa có hàm getPostsByUserId, hãy xem lại hướng dẫn trước để thêm vào db
    final posts = await db.getPostsByUserId(widget.user.id);

    if (mounted) {
      setState(() {
        _userPosts = posts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.userName),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) {
          return [
            SliverList(
              delegate: SliverChildListDelegate([_buildProfileHeader()]),
            ),
          ];
        },
        body: _buildPostGrid(),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[300],
                backgroundImage: (widget.user.avatarUrl != null &&
                    widget.user.avatarUrl!.isNotEmpty)
                    ? (widget.user.avatarUrl!.startsWith('http')
                    ? NetworkImage(widget.user.avatarUrl!)
                    : FileImage(File(widget.user.avatarUrl!))) as ImageProvider
                    : null,
                child: (widget.user.avatarUrl == null ||
                    widget.user.avatarUrl!.isEmpty)
                    ? Text(widget.user.userName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 30))
                    : null,
              ),
              const SizedBox(width: 20),
              // Số liệu bài viết
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          _userPosts.length.toString(),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Text("Bài viết",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tên hiển thị
          Text(
            widget.user.fullName ?? widget.user.userName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          // Tiểu sử
          if (widget.user.bio != null && widget.user.bio!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(widget.user.bio!),
            ),

          const SizedBox(height: 20),
          // Nút Follow (Demo - chưa có logic)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Tính năng Follow đang phát triển")));
              },
              child: const Text("Theo dõi"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostGrid() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_userPosts.isEmpty) {
      return const Center(
        child: Text("Người dùng này chưa có bài viết nào.",
            style: TextStyle(color: Colors.grey)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      itemCount: _userPosts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemBuilder: (context, index) {
        final post = _userPosts[index];

        // Logic hiển thị ảnh (tương tự file cũ)
        Widget imageWidget;
        if (post.imageUrl != null && post.imageUrl.isNotEmpty) {
          bool isNetwork = post.imageUrl.startsWith('http');
          imageWidget = isNetwork
              ? Image.network(post.imageUrl, fit: BoxFit.cover)
              : Image.file(File(post.imageUrl), fit: BoxFit.cover);
        } else {
          imageWidget = Container(color: Colors.blue[50], child: Center(child: Text(post.caption ?? '')));
        }

        return InkWell(
          onTap: () {
            // Chuyển sang xem chi tiết bài viết
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => PostDetailScreen(post: post, user: widget.user)
            ));
          },
          child: imageWidget,
        );
      },
    );
  }
}
