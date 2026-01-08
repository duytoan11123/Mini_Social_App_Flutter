import 'package:flutter/material.dart';
import 'dart:io';

import '../../Models/user_model.dart';
import '../../Models/post_model.dart';
import '../Auth/login_screen.dart';
import 'edit_profile_screen.dart';
import '../Post/post_detail_screen.dart';
import '../../Controllers/user_controller.dart';
import '../../Controllers/auth_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  List<PostModel> _userPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final currentUser = AuthController.instance.currentUser;
    if (currentUser == null) return;

    // 1. Get User Info (refresh from API)
    final user = await UserController.instance.getUserById(currentUser.id);

    // 2. Get User Posts
    final posts = await UserController.instance.getPostsByUserId(
      currentUser.id,
    );

    if (mounted) {
      setState(() {
        _user = user;
        _userPosts = posts;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await AuthController.instance.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text("Lỗi không tải được Profile")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _user!.userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
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
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    (_user!.avatarUrl != null && _user!.avatarUrl!.isNotEmpty)
                    ? (_user!.avatarUrl!.startsWith('http')
                          ? NetworkImage(_user!.avatarUrl!)
                          : FileImage(File(_user!.avatarUrl!)) as ImageProvider)
                    : null,

                child: (_user!.avatarUrl == null || _user!.avatarUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 40, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(_userPosts.length, "Bài viết"),
                    StreamBuilder<int>(
                      stream: UserController.instance.watchFollowersCount(
                        _user!.id,
                      ),
                      builder: (context, snapshot) {
                        return _buildStatColumn(
                          snapshot.data ?? _user!.followersCount,
                          "Người theo dõi",
                        );
                      },
                    ),
                    StreamBuilder<int>(
                      stream: UserController.instance.watchFollowingCount(
                        _user!.id,
                      ),
                      builder: (context, snapshot) {
                        return _buildStatColumn(
                          snapshot.data ?? _user!.followingCount,
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

          Text(
            _user!.fullName ?? _user!.userName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),

          if (_user!.bio != null && _user!.bio!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                _user!.bio!,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    // TODO: Update EditProfileScreen to use UserModel
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(user: _user!),
                      ),
                    );
                    if (result == true) {
                      _loadData();
                    }
                    /*
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Tính năng chỉnh sửa đang được cập nhật"),
                      ),
                    );
                    */
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),

                  child: const Text(
                    "Chỉnh sửa trang cá nhân",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(int num, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          num.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
        ),
      ],
    );
  }

  Widget _buildPostGrid() {
    if (_userPosts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text("Chưa có bài viết nào"),
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
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final post = _userPosts[index];

        Widget imageWidget;
        if (post.imageUrl.isNotEmpty) {
          imageWidget = post.imageUrl.startsWith('http')
              ? Image.network(
                  post.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey[200]),
                )
              : Image.file(
                  File(post.imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey[200]),
                );
        } else {
          imageWidget = Container(
            color: Colors.blue[50],
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Text(
                post.caption ?? '',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(post: post),
              ),
            );
          },
          child: Hero(tag: "post_${post.id}", child: imageWidget),
        );
      },
    );
  }
}
