import 'package:flutter/material.dart';
import 'dart:io';

import '../../Models/user_model.dart';
import '../../Models/post_model.dart';
import '../Post/post_detail_screen.dart';
import '../../Controllers/user_controller.dart';
import '../../Controllers/auth_controller.dart';

class UserProfileScreen extends StatefulWidget {
  final UserModel user; // Use UserModel

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  List<PostModel> _userPosts = [];
  bool _isLoading = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadUserPosts();
    _checkFollowingStatus();
  }

  Future<void> _checkFollowingStatus() async {
    final currentUser = AuthController.instance.currentUser;
    if (currentUser == null) return;

    final status = await UserController.instance.isFollowing(
      currentUser.id,
      widget.user.id,
    );

    if (mounted) {
      setState(() {
        _isFollowing = status;
      });
    }
  }

  Future<void> _handleToggleFollow() async {
    final currentUser = AuthController.instance.currentUser;
    if (currentUser == null) return;

    await UserController.instance.toggleFollow(widget.user.id);

    setState(() {
      _isFollowing = !_isFollowing;
    });
  }

  Future<void> _loadUserPosts() async {
    final posts = await UserController.instance.getPostsByUserId(
      widget.user.id,
    );
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
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          _userPosts.length.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Bài viết",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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

          // Show follow button if not current user
          if (AuthController.instance.currentUser?.id != widget.user.id)
            SizedBox(
              width: double.infinity,
              child: _isFollowing
                  ? OutlinedButton(
                      onPressed: _handleToggleFollow,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
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
                      ),
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
        child: Text(
          "Người dùng này chưa có bài viết nào.",
          style: TextStyle(color: Colors.grey),
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
            child: Center(child: Text(post.caption ?? '')),
          );
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
            );
          },
          child: Hero(
            tag: 'user_post_${post.id}',
            child: imageWidget,
          ), // Avoid tag conflict with Feed
        );
      },
    );
  }
}
