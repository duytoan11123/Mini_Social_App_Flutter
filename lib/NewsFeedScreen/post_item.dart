import 'package:flutter/material.dart';
import '../Database/app_database.dart';
import 'dart:io';

class PostItem extends StatelessWidget {
  final PostWithUser post;

  const PostItem({super.key, required this.post});

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
            children: const [
              Icon(Icons.favorite_border, size: 28),
              SizedBox(width: 16),
              Icon(Icons.comment_outlined, size: 28),
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

        const SizedBox(height: 16.0),
        const Divider(height: 1, thickness: 1),
      ],
    );
  }
}
