import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../Database/app_database.dart';
import '../../Controllers/comment_controller.dart';

// Emoji reactions
const Map<String, String> reactionEmojis = {
  'like': '👍',
  'love': '❤️',
  'haha': '😆',
  'wow': '😮',
  'sad': '😢',
  'angry': '😠',
};

class CommentsScreen extends StatefulWidget {
  final int postId;

  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  int? _replyToCommentId;
  String? _replyToUserName;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  void _setReplyTo(int commentId, String userName) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUserName = userName;
    });
    _commentController.clear();
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToUserName = null;
    });
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty && _selectedImage == null) return;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để bình luận')),
      );
      return;
    }

    await CommentController.instance.addComment(
      postId: widget.postId,
      userId: currentUserId!,
      content: content,
      imageUrl: _selectedImage?.path,
      parentId: _replyToCommentId,
    );

    _commentController.clear();
    setState(() {
      _selectedImage = null;
      _replyToCommentId = null;
      _replyToUserName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bình luận')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<CommentWithUser>>(
              stream: CommentController.instance.watchCommentsForPost(
                widget.postId,
              ),
              builder: (context, snapshot) {
                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return const Center(child: Text('Chưa có bình luận nào'));
                }
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    return _CommentWithReplies(
                      commentWithUser: comments[index],
                      onReply: _setReplyTo,
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyToUserName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  Text(
                    'Đang trả lời ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    _replyToUserName!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.all(8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image, color: Colors.blue),
                ),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: _replyToUserName != null
                          ? 'Trả lời $_replyToUserName...'
                          : 'Viết bình luận...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget hiển thị comment + replies bên dưới
class _CommentWithReplies extends StatelessWidget {
  final CommentWithUser commentWithUser;
  final Function(int, String) onReply; // parentId, userName

  const _CommentWithReplies({
    required this.commentWithUser,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final rootCommentId = commentWithUser.comment.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CommentItem(
          commentWithUser: commentWithUser,
          onReply: () => onReply(rootCommentId, commentWithUser.user.userName),
          isReply: false,
        ),
        // Replies luôn hiển thị bên dưới
        StreamBuilder<List<CommentWithUser>>(
          stream: CommentController.instance.watchRepliesForComment(
            rootCommentId,
          ),
          builder: (context, snapshot) {
            final replies = snapshot.data ?? [];
            if (replies.isEmpty) return const SizedBox.shrink();
            return Column(
              children: replies
                  .map(
                    (r) => _CommentItem(
                      commentWithUser: r,
                      // Reply của reply → vẫn reply vào comment gốc
                      onReply: () => onReply(rootCommentId, r.user.userName),
                      isReply: true,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _CommentItem extends StatelessWidget {
  final CommentWithUser commentWithUser;
  final VoidCallback onReply;
  final bool isReply;

  const _CommentItem({
    super.key,
    required this.commentWithUser,
    required this.onReply,
    this.isReply = false,
  });

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Xóa bình luận',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(ctx); // Đóng menu
              // Gọi lệnh xóa trong database
              await db.deleteComment(commentWithUser.comment.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa bình luận')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    if (currentUserId == null) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: reactionEmojis.entries
              .map(
                (e) => GestureDetector(
                  onTap: () {
                    db.toggleReaction(
                      commentWithUser.comment.id,
                      currentUserId!,
                      e.key,
                    );
                    Navigator.pop(ctx);
                  },
                  child: Text(e.value, style: const TextStyle(fontSize: 32)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = commentWithUser;
    // Kiểm tra xem đây có phải comment của mình không
    final isMyComment =
        currentUserId != null && c.comment.userId == currentUserId;
    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 50.0 : 12.0,
        right: 12.0,
        top: 8.0,
        bottom: 4.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 18,
            backgroundImage: NetworkImage(
              c.user.avatarUrl ?? 'https://via.placeholder.com/150',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  // Nếu là comment của mình thì cho phép nhấn giữ để xóa
                  onLongPress: isMyComment ? () => _showOptions(context) : null,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.user.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (c.comment.content != null &&
                                c.comment.content!.isNotEmpty)
                              Text(c.comment.content!),
                          ],
                        ),
                      ),
                      // Reaction badge
                      Positioned(
                        bottom: -8,
                        right: 0,
                        child: _ReactionBadge(commentId: c.comment.id),
                      ),
                    ],
                  ),
                ),
                // Ảnh đính kèm
                if (c.comment.imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(c.comment.imageUrl!),
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                // Actions
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 8),
                  child: Row(
                    children: [
                      Text(
                        _formatTime(c.comment.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _showReactionPicker(context),
                        child: _UserReactionText(commentId: c.comment.id),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: onReply,
                        child: Text(
                          'Trả lời',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    return '${diff.inDays} ngày';
  }
}

// Hiển thị text "Thích" hoặc emoji nếu user đã react
class _UserReactionText extends StatelessWidget {
  final int commentId;

  const _UserReactionText({required this.commentId});

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return Text(
        'Thích',
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return FutureBuilder<String?>(
      future: CommentController.instance.getUserReaction(
        commentId,
        currentUserId!,
      ),
      builder: (context, snapshot) {
        final reaction = snapshot.data;
        if (reaction != null && reactionEmojis.containsKey(reaction)) {
          return Text(
            reactionEmojis[reaction]!,
            style: const TextStyle(fontSize: 14),
          );
        }
        return Text(
          'Thích',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }
}

// Badge hiển thị tổng reactions
class _ReactionBadge extends StatelessWidget {
  final int commentId;

  const _ReactionBadge({required this.commentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReactionCount>>(
      stream: CommentController.instance.watchReactionsForComment(commentId),
      builder: (context, snapshot) {
        final reactions = snapshot.data ?? [];
        if (reactions.isEmpty) return const SizedBox.shrink();

        final total = reactions.fold<int>(0, (sum, r) => sum + r.count);
        final emojis = reactions
            .take(3)
            .map((r) => reactionEmojis[r.reaction] ?? '')
            .join();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emojis, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                '$total',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}
