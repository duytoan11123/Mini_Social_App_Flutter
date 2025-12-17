
import 'package:flutter/material.dart';
import '../Entity/Post.dart';

class PostItem extends StatelessWidget {
  final Post post;

  const PostItem({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header: Avatar và Tên người dùng
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(post.userAvatarUrl),
              ),
              const SizedBox(width: 8.0),
              Text(
                post.userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Icon(Icons.more_vert),
            ],
          ),
        ),

        // 2. Khu vực Ảnh
        Image.network(
          post.imageUrl,
          width: double.infinity,
          height: 400,
          fit: BoxFit.cover,
        ),

        // 3. Khu vực Icon Tương tác (Không có nút Chia sẻ)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: const [
              Icon(Icons.favorite_border, size: 28),
              SizedBox(width: 16),
              Icon(Icons.comment_outlined, size: 28),
              // KHÔNG có nút Chia sẻ (Send/Share) theo yêu cầu
            ],
          ),
        ),

        // 4. Khu vực Likes
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Text(
            '${post.likes} lượt thích',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        // 5. Khu vực Caption
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: <TextSpan>[
                TextSpan(
                    text: '${post.userName} ',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: post.caption),
              ],
            ),
          ),
        ),

        // Khoảng cách giữa các bài đăng
        const SizedBox(height: 16.0),
        const Divider(height: 1, thickness: 1),
      ],
    );
  }
}
