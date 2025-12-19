import 'package:flutter/material.dart';
import '../Database/app_database.dart';
import 'dart:io';
import 'comments_screen.dart';

class PostItem extends StatelessWidget {
  final PostWithUser post;

  const PostItem({super.key, required this.post});

  void _openComments(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(postId: post.post.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                backgroundImage: NetworkImage(
                  post.user.avatarUrl ?? 'https://via.placeholder.com/150',
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                post.user.userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Icon(Icons.more_vert),
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
              const Icon(Icons.favorite_border, size: 28),
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
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: comments.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: NetworkImage(
                          c.user.avatarUrl ?? 'https://via.placeholder.com/150',
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
                                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                )).toList(),
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
