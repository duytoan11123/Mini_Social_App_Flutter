import '../../Models/post_model.dart';
import '../../Controllers/post_controller.dart';
import 'package:flutter/material.dart';
import 'post_item.dart';

class PostListWidget extends StatefulWidget {
  const PostListWidget({super.key});

  @override
  State<PostListWidget> createState() => _PostListWidgetState();
}

class _PostListWidgetState extends State<PostListWidget> {
  @override
  void initState() {
    super.initState();
    PostController.instance.fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PostModel>>(
      stream: PostController.instance.postsStream,
      builder: (context, snapshot) {
        final posts = snapshot.data ?? [];
        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return PostItem(key: ValueKey(posts[index].id), post: posts[index]);
          },
        );
      },
    );
  }
}
