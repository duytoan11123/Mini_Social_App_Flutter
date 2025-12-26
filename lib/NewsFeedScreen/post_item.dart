import 'package:flutter/material.dart';
import '../Database/app_database.dart';
import 'package:drift/drift.dart'
    hide Column; // Hide Column to avoid conflict with Material Column
import 'dart:io';
import 'comments_screen.dart';

class PostItem extends StatefulWidget {
  final PostWithUser post;

  const PostItem({super.key, required this.post});

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
  }

  @override
  void didUpdateWidget(covariant PostItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.post.id != oldWidget.post.post.id) {
      _checkLikeStatus();
    }
  }

  Future<void> _checkLikeStatus() async {
    if (currentUserId == null) return;
    final liked = await db.hasUserLikedPost(
      widget.post.post.id,
      currentUserId!,
    );
    if (mounted) {
      setState(() {
        _isLiked = liked;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để thích bài viết')),
      );
      return;
    }

    // Optimistic update
    setState(() {
      _isLiked = !_isLiked;
    });

    try {
      await db.togglePostLike(widget.post.post.id, currentUserId!);
    } catch (e) {
      // Revert if error
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
        });
      }
      debugPrint('Error toggling like: $e');
    }
  }

  void _openComments(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(postId: widget.post.post.id),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài viết?'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa bài viết này không? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Đóng dialog
              await db.deletePost(widget.post.post.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa bài viết')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final TextEditingController _editController = TextEditingController(
      text: widget.post.post.caption ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa bài viết'),
        content: TextField(
          controller: _editController,
          decoration: const InputDecoration(hintText: 'Nhập nội dung mới...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final newCaption = _editController.text.trim();
              Navigator.pop(context); // Đóng dialog

              final updatedPost = widget.post.post.copyWith(
                caption: Value(newCaption),
              );
              await db.updatePost(updatedPost);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật bài viết')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //  Avatar và Tên người dùng
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    (post.user.avatarUrl != null &&
                        post.user.avatarUrl!.isNotEmpty)
                    ? FileImage(File(post.user.avatarUrl!))
                    : null,
                // 👇 FALLBACK: Nếu không có ảnh thì hiện icon người
                child:
                    (post.user.avatarUrl == null ||
                        post.user.avatarUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 20, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 8.0),
              Text(
                post.user.userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (post.user.id == currentUserId)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditDialog();
                    } else if (value == 'delete') {
                      _showDeleteDialog();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Chỉnh sửa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ];
                  },
                  icon: const Icon(Icons.more_vert),
                ),
            ],
          ),
        ),
        // Ảnh bài đăng
        Image.file(
          File(post.post.imageUrl),
          width: double.infinity,
          height: 400,
          fit: BoxFit.cover,
        ),
        // Biểu tượng Thích và Bình luận
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: _toggleLike,
                child: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 28,
                  color: _isLiked ? Colors.red : null,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _openComments(context),
                child: const Icon(Icons.comment_outlined, size: 28),
              ),
            ],
          ),
        ),

        // Số lượt thích
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Text(
            '${post.post.likes} lượt thích',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        // Caption bài đăng
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: <TextSpan>[
                TextSpan(
                  text: '${post.user.userName} ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: post.post.caption),
              ],
            ),
          ),
        ),

        // Xem tất cả bình luận
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: GestureDetector(
            onTap: () => _openComments(context),
            child: FutureBuilder<int>(
              future: db.getCommentCount(post.post.id),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count <= 2) return const SizedBox.shrink();
                return Text(
                  'Xem tất cả $count bình luận',
                  style: TextStyle(color: Colors.grey[600]),
                );
              },
            ),
          ),
        ),

        // Hiển thị 2 bình luận mới nhất
        FutureBuilder<List<CommentWithUser>>(
          future: db.getRecentComments(post.post.id, limit: 2),
          builder: (context, snapshot) {
            final comments = snapshot.data ?? [];
            if (comments.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: comments
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundImage: NetworkImage(
                                c.user.avatarUrl ??
                                    'https://via.placeholder.com/150',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: DefaultTextStyle.of(context).style,
                                      children: [
                                        TextSpan(
                                          text: '${c.user.userName}  ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(text: c.comment.content),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),

        const SizedBox(height: 16.0),
        const Divider(height: 1, thickness: 1),
      ],
    );
  }
}
