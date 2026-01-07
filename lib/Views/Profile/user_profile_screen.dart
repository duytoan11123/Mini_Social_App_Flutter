import 'dart:io';
import 'package:flutter/material.dart';
import '../../Database/app_database.dart'; // Import để lấy model User, Post và currentUserId

import '../Post/post_detail_screen.dart';
import '../../Controllers/profile_controller.dart'; // 👈 Import Controller

class UserProfileScreen extends StatefulWidget {
  final User user; // User được truyền từ màn hình Search/Feed

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  List<Post> _userPosts = [];
  bool _isLoading = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 👇 Load tất cả dữ liệu cần thiết một lần
  Future<void> _loadData() async {
    if (currentUserId == null) return;

    try {
      // Chạy song song: Lấy bài viết VÀ Kiểm tra trạng thái Follow
      final results = await Future.wait([
        ProfileController.instance.getUserPosts(widget.user.id),
        ProfileController.instance.checkIsFollowing(
          currentUserId!,
          widget.user.id,
        ),
      ]);

      if (mounted) {
        setState(() {
          _userPosts = results[0] as List<Post>;
          _isFollowing = results[1] as bool;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi load user profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 👇 Xử lý Follow/Unfollow qua Controller
  Future<void> _handleToggleFollow() async {
    if (currentUserId == null) return;

    // Gọi Controller để xử lý logic DB
    await ProfileController.instance.toggleFollow(
      currentUserId!,
      widget.user.id,
    );

    // Cập nhật UI ngay lập tức
    if (mounted) {
      setState(() {
        _isFollowing = !_isFollowing;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.user.userName)),
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
                backgroundImage:
                    (widget.user.avatarUrl != null &&
                        widget.user.avatarUrl!.isNotEmpty)
                    ? (widget.user.avatarUrl!.startsWith('http')
                          ? NetworkImage(widget.user.avatarUrl!)
                          : FileImage(File(widget.user.avatarUrl!))
                                as ImageProvider)
                    : null,
                child:
                    (widget.user.avatarUrl == null ||
                        widget.user.avatarUrl!.isEmpty)
                    ? Text(
                        widget.user.userName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 30),
                      )
                    : null,
              ),
              const SizedBox(width: 20),

              // Số liệu thống kê
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Số bài viết
                    _buildStatColumn(_userPosts.length, "Bài viết"),

                    // 👇 Số người theo dõi (Dùng Stream để tự cập nhật khi bấm Follow)
                    StreamBuilder<int>(
                      stream: ProfileController.instance.watchFollowersCount(
                        widget.user.id,
                      ),
                      builder: (context, snapshot) {
                        return _buildStatColumn(
                          snapshot.data ?? 0,
                          "Người theo dõi",
                        );
                      },
                    ),

                    // 👇 Đang theo dõi
                    StreamBuilder<int>(
                      stream: ProfileController.instance.watchFollowingCount(
                        widget.user.id,
                      ),
                      builder: (context, snapshot) {
                        return _buildStatColumn(
                          snapshot.data ?? 0,
                          "Đang theo dõi",
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Tên & Bio
          Text(
            widget.user.fullName ?? widget.user.userName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          if (widget.user.bio != null && widget.user.bio!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(widget.user.bio!),
            ),

          const SizedBox(height: 20),

          // Nút Follow/Unfollow
          if (currentUserId != widget.user.id)
            SizedBox(
              width: double.infinity,
              child: _isFollowing
                  ? OutlinedButton(
                      onPressed: _handleToggleFollow,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Đang theo dõi",
                        style: TextStyle(color: Colors.black),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _handleToggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Theo dõi"),
                    ),
            ),
        ],
      ),
    );
  }

  // Widget con hiển thị cột số liệu (Tái sử dụng code cho gọn)
  Widget _buildStatColumn(int num, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          num.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildPostGrid() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_userPosts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text("Chưa có bài viết nào", style: TextStyle(color: Colors.grey)),
          ],
        ),
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

        // Logic hiển thị ảnh (Network hoặc Local)
        Widget imageWidget;
        if (post.imageUrl.isNotEmpty) {
          if (post.imageUrl.startsWith('http')) {
            imageWidget = Image.network(post.imageUrl, fit: BoxFit.cover);
          } else {
            imageWidget = Image.file(File(post.imageUrl), fit: BoxFit.cover);
          }
        } else {
          imageWidget = Container(color: Colors.grey[200]);
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(post: post, user: widget.user),
              ),
            );
          },
          child: Hero(
            tag:
                "user_profile_post_${post.id}", // Tag khác với ProfileScreen để tránh lỗi Hero
            child: imageWidget,
          ),
        );
      },
    );
  }
}
