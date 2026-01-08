import 'package:flutter/material.dart';

import 'dart:io';
import '../../Models/comment_model.dart';
import '../../Controllers/comment_controller.dart';
import '../../Controllers/auth_controller.dart'; // for currentUser

const Map<String, String> reactionEmojis = {
  'like': '👍',
  'love': '❤️',
  'haha': '😆',
};

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  File? _selectedImage;
  String? _replyToCommentId;
  String? _replyToUserName;

  // State for comments list
  List<CommentModel> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoading = true);
    try {
      final comments = await CommentController.instance.getRecentComments(
        widget.postId,
        limit: 100,
      );
      setState(() {
        _comments = comments;
      });
    } catch (e) {
      debugPrint("Error fetching comments: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _setReplyTo(String commentId, String userName) {
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

    if (AuthController.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để bình luận')),
      );
      return;
    }

    await CommentController.instance.addComment(
      widget.postId,
      content,
      parentId: _replyToCommentId,
    );

    // Refresh comments
    await _fetchComments();

    _commentController.clear();
    setState(() {
      _selectedImage = null;
      _replyToCommentId = null;
      _replyToUserName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rootComments = _comments.where((c) => c.parentId == null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Bình luận')),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : rootComments.isEmpty
                ? const Center(child: Text('Chưa có bình luận nào'))
                : ListView.builder(
                    itemCount: rootComments.length,
                    itemBuilder: (context, index) {
                      return _CommentWithReplies(
                        comment: rootComments[index],
                        allComments: _comments, // Pass all to find replies
                        onReply: _setReplyTo,
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
          // Image preview skipped for brevity in this simplified version, can add back if needed
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: null, // Image upload not fully wired to API yet
                  icon: const Icon(Icons.image, color: Colors.grey),
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

class _CommentWithReplies extends StatelessWidget {
  final CommentModel comment;
  final List<CommentModel> allComments;
  final Function(String, String) onReply;

  const _CommentWithReplies({
    required this.comment,
    required this.allComments,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final replies = allComments.where((c) => c.parentId == comment.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CommentItem(
          comment: comment,
          onReply: () =>
              onReply(comment.id, comment.user?.userName ?? 'Unknown'),
          isReply: false,
        ),
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40.0), // Indent replies
            child: Column(
              children: replies
                  .map(
                    (r) => _CommentItem(
                      comment: r,
                      onReply: () => onReply(
                        comment.id,
                        r.user?.userName ?? 'Unknown',
                      ), // Reply to root
                      isReply: true,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _CommentItem extends StatefulWidget {
  final CommentModel comment;
  final VoidCallback onReply;
  final bool isReply;

  const _CommentItem({
    required this.comment,
    required this.onReply,
    this.isReply = false,
  });

  @override
  State<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<_CommentItem> {
  bool _isLiked = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.comment.isLiked;
    _likesCount = widget.comment.likesCount;
  }

  Future<void> _toggleLike() async {
    if (AuthController.instance.currentUser == null) return;

    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    try {
      await CommentController.instance.toggleLike(widget.comment.id);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likesCount += _isLiked ? 1 : -1;
        });
      }
    }
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return 'Unknown';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) return '${date.day}/${date.month}';
    if (diff.inDays > 0) return '${diff.inDays} ngày';
    if (diff.inHours > 0) return '${diff.inHours} giờ';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút';
    return 'Vừa xong';
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.comment.user;
    final userName = user?.userName ?? 'Unknown';
    final avatarUrl = user?.avatarUrl;

    return Padding(
      padding: EdgeInsets.only(
        left: widget.isReply ? 10.0 : 12.0,
        right: 12.0,
        top: 8.0,
        bottom: 4.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: widget.isReply ? 14 : 18,
            backgroundColor: Colors.grey[300],
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? (avatarUrl.startsWith('http')
                      ? NetworkImage(avatarUrl)
                      : FileImage(File(avatarUrl)) as ImageProvider)
                : null,
            onBackgroundImageError: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? (_, __) {}
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(widget.comment.content),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 8),
                  child: Row(
                    children: [
                      Text(
                        _timeAgo(widget.comment.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: widget.onReply,
                        child: Text(
                          'Trả lời',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Text(
                          _isLiked ? 'Đã thích' : 'Thích',
                          style: TextStyle(
                            color: _isLiked ? Colors.blue : Colors.grey[700],
                            fontSize: 12,
                            fontWeight: _isLiked
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_likesCount > 0) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.thumb_up,
                          size: 10,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$_likesCount',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
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
}
