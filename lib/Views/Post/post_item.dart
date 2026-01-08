import 'package:flutter/material.dart';
import 'dart:io';
import '../../Controllers/post_controller.dart';
import '../../Controllers/auth_controller.dart';
import '../../Models/post_model.dart';
import '../../Controllers/user_controller.dart';
import '../Comment/comments_screen.dart';
import '../Post/post_detail_screen.dart';

class PostItem extends StatefulWidget {
  final PostModel post;

  const PostItem({super.key, required this.post});

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  bool _isLiked = false;
  int _likesCount = 0;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likes; // Fixed property name
    _checkLikeStatus();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final currentUser = AuthController.instance.currentUser;
    if (currentUser == null || widget.post.author == null) return;
    // Ownership check is now in build()

    bool following = await UserController.instance.isFollowing(
      currentUser.id,
      widget.post.author!.id,
    );
    if (mounted) {
      setState(() {
        _isFollowing = following;
      });
    }
  }

  Future<void> _handleFollowToggle() async {
    final currentUser = AuthController.instance.currentUser;
    if (currentUser == null) {
      _showLoginRequirement();
      return;
    }

    if (widget.post.author == null) return;

    // Optimistic update
    setState(() {
      _isFollowing = !_isFollowing;
    });

    try {
      await UserController.instance.toggleFollow(widget.post.author!.id);
    } catch (e) {
      // Revert
      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
        });
      }
      debugPrint("Follow error: $e");
    }
  }

  bool _isToggling = false;

  Future<void> _checkLikeStatus() async {
    bool liked = await PostController.instance.hasLiked(widget.post.id);
    if (mounted) {
      setState(() {
        _isLiked = liked;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_isToggling) return; // Prevent multiple clicks

    final currentUser = AuthController.instance.currentUser;
    if (currentUser == null) {
      _showLoginRequirement();
      return;
    }

    setState(() {
      _isToggling = true;
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    try {
      await PostController.instance.toggleLike(widget.post.id);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likesCount += _isLiked ? 1 : -1;
        });
      }
      debugPrint("Like error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isToggling = false;
        });
      }
    }
  }

  void _showLoginRequirement() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vui lòng đăng nhập để thực hiện chức năng này'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthController.instance.currentUser;
    final isOwnPost = currentUser?.id == widget.post.author?.id;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[200],
              backgroundImage: _getAvatarImage(widget.post.author?.avatarUrl),
              onBackgroundImageError:
                  _getAvatarImage(widget.post.author?.avatarUrl) != null
                  ? (_, __) {}
                  : null,
              child: _getAvatarImage(widget.post.author?.avatarUrl) == null
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    widget.post.author?.userName ?? "Unknown",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isOwnPost && widget.post.author != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _handleFollowToggle,
                    child: Text(
                      _isFollowing ? "• Đang theo dõi" : "• Theo dõi",
                      style: TextStyle(
                        color: _isFollowing ? Colors.grey : Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showMoreOptions(context),
            ),
          ),

          // Image
          if (widget.post.imageUrl.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(post: widget.post),
                  ),
                );
              },
              child: AspectRatio(
                aspectRatio: 1,
                child: widget.post.imageUrl.startsWith('http')
                    ? Image.network(
                        widget.post.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.error),
                        ),
                      )
                    : Image.file(
                        File(widget.post.imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.error),
                        ),
                      ),
              ),
            ),

          // Actions
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.black,
                ),
                onPressed: _toggleLike,
              ),
              IconButton(
                icon: const Icon(Icons.mode_comment_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CommentsScreen(postId: widget.post.id),
                    ),
                  );
                },
              ),

              // IconButton(
              //   icon: const Icon(Icons.send_outlined),
              //   onPressed: () {},
              // ),
              // const Spacer(),
              // IconButton(
              //   icon: const Icon(Icons.bookmark_border),
              //   onPressed: () {},
              // ),
            ],
          ),

          // Likes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$_likesCount lượt thích',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // Caption
          if (widget.post.caption != null && widget.post.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: '${widget.post.author?.userName ?? "Unknown"} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: widget.post.caption),
                  ],
                ),
              ),
            ),

          // View Comments
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CommentsScreen(postId: widget.post.id),
                  ),
                );
              },
              child: const Text(
                'Xem tất cả bình luận',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

          // Time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              _timeAgo(widget.post.createdAt ?? DateTime.now()),
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (AuthController.instance.currentUser?.id ==
                  widget.post.author?.id) ...[
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Chỉnh sửa'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Xóa bài viết',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await PostController.instance.deletePost(widget.post.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Xoá bài viết thành công'),
                        ),
                      );
                    }
                  },
                ),
              ] else
                ListTile(
                  leading: const Icon(Icons.report),
                  title: const Text('Báo cáo'),
                  onTap: () => Navigator.pop(context),
                ),
            ],
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }

  void _showEditDialog(BuildContext context) {
    final TextEditingController captionController = TextEditingController(
      text: widget.post.caption,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chỉnh sửa bài viết'),
          content: TextField(
            controller: captionController,
            decoration: const InputDecoration(
              hintText: 'Nhập nội dung mới...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (captionController.text.trim().isEmpty) return;

                await PostController.instance.updatePost(
                  widget.post.id,
                  captionController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cập nhật thành công')),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  ImageProvider? _getAvatarImage(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return NetworkImage(url);
    if (url.startsWith('uploads/') || url.startsWith('uploads\\')) {
      return NetworkImage('https://flutter-demo-api.onrender.com/$url');
    }
    return FileImage(File(url));
  }
}
