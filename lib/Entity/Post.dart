
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