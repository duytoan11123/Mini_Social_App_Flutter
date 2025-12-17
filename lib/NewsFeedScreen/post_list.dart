import '../Database/app_database.dart';
import 'package:flutter/material.dart';
import 'post_item.dart';


class PostListWidget extends StatelessWidget{
  const PostListWidget({super.key});
  @override
  Widget build (BuildContext context){
    return StreamBuilder<List<PostWithUser>>(
      stream: db.watchPostsWithUsers(),
      builder: (context, snapshot) {
        final posts = snapshot.data ?? [];
        print ('Number of posts: ${posts.length}');
        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return PostItem(post: posts[index]);
          },
        );
      },
    );
  }

}