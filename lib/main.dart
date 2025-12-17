import 'package:flutter/material.dart';
import 'NewsFeedScreen/createPostModal.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instagram Feed Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1
        ),
      ),
      home: const NewsFeedScreen(),
    );
  }
}

//Định nghĩa dữ liệu mẫu cho mỗi bài đăng
class Post{
  final String userName;
  final String userAvatarUrl;
  final String imageUrl;
  final String caption;
  final int likes;

  Post({
    required this.userName,
    required this.userAvatarUrl,
    required this.imageUrl,
    required this.caption,
    required this.likes,
  });
}

final List<Post> samplePosts = [
  Post(
    userName: 'alice',
    userAvatarUrl: 'https://example.com/avatars/alice.png',
    imageUrl: 'https://example.com/images/post1.png',
    caption: 'Enjoying the sunny day!',
    likes: 120,
  ),
  Post(
    userName: 'bob',
    userAvatarUrl: 'https://example.com/avatars/bob.png',
    imageUrl: 'https://example.com/images/post2.png',
    caption: 'Delicious homemade pizza.',
    likes: 95,
  ),
  Post(
    userName: 'charlie',
    userAvatarUrl: 'https://example.com/avatars/charlie.png',
    imageUrl: 'https://example.com/images/post3.png',
    caption: 'Hiking adventures!',
    likes: 150,
  ),
];

class NewsFeedScreen extends StatelessWidget{
  const NewsFeedScreen({super.key});
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("Social App", style: TextStyle(fontFamily: 'Billabong', fontSize:30)),  
        centerTitle: false,
        actions:const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.favorite_border), // Biểu tượng trái tim
          ),
        ]
      ),
      body: ListView.builder(
        itemCount: samplePosts.length,
        itemBuilder: (context, index) {
          return PostItem(post: samplePosts[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Xử lý khi nhấn nút Đăng ảnh (mở màn hình tạo bài đăng mới)
          _showCreatePostModal(context);
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }

  void _showCreatePostModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext bc) {
        // Sử dụng Padding để đẩy nội dung lên khi bàn phím xuất hiện
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: const CreatePostForm(),
        );
      },
    );
  }
}

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

