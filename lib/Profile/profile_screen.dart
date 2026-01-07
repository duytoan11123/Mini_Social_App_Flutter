import 'dart:io';
import 'package:flutter/material.dart';
import '../Database/app_database.dart';
import '../main.dart'; // Chứa biến db và currentUserId
import '../Login/login_screen.dart';
import '../Login/auth_storage.dart';
import '../NewsFeedScreen/post_detail_screen.dart';
import 'edit_profile_screen.dart'; //

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  List<Post> _userPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Hàm load cả thông tin user VÀ bài viết của user đó
  Future<void> _loadData() async {
    if (currentUserId == null) return;

    // 1. Lấy thông tin User
    final user = await db.getUserById(currentUserId!);

    // 2. Lấy danh sách bài viết của User này (MỚI)
    final posts = await db.getPostsByUserId(currentUserId!);

    if (mounted) {
      setState(() {
        _user = user;
        _userPosts = posts; // Lưu bài viết vào list
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await AuthStorage.logout();
    currentUserId = null;
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text("Lỗi không tải được Profile")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _user!.userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _handleLogout, // Tạm thời để nút logout ở đây
          ),
        ],
      ),
      body: NestedScrollView(
        // Phần Header (Thông tin cá nhân) cuộn được
        headerSliverBuilder: (context, _) {
          return [
            SliverList(
              delegate: SliverChildListDelegate([_buildProfileHeader()]),
            ),
          ];
        },
        // 👇 Phần Body: Hiển thị trực tiếp Lưới ảnh (bỏ TabBar và TabBarView)
        body: _buildPostGrid(),
      ), // Tab 2: Demo
    );
  }

  // ---------------------------------------------------------
  // 👇 DÁN ĐOẠN NÀY VÀO ĐỂ SỬA LỖI _buildProfileHeader
  // ---------------------------------------------------------

  // Widget hiển thị thông tin cá nhân (Header)
  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 1. Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    (_user!.avatarUrl != null && _user!.avatarUrl!.isNotEmpty)
                    ? FileImage(File(_user!.avatarUrl!))
                    : null,

                child: (_user!.avatarUrl == null || _user!.avatarUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 40, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Căn giữa số liệu bài viết
                  children: [
                    // Số bài viết
                    _buildStatColumn(_userPosts.length, "Bài viết"),

                    //Người theo dõi
                    StreamBuilder<int>(
                      stream: db.watchFollowersCount(_user!.id),
                      builder: (context, snapshot){
                        return _buildStatColumn(snapshot.data ?? 0, "Người theo dõi");
                      },
                    ),
                    // Đang theo dõi
                    StreamBuilder<int>(
                      stream: db.watchFollowingCount(_user!.id),
                      builder: (context, snapshot) {
                        return _buildStatColumn(
                            snapshot.data ?? 0, "Đang theo dõi");
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3. Hiển thị Fullname (Tên đầy đủ)
          // Nếu không có fullname thì hiện username
          Text(
            _user!.fullName ?? _user!.userName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ), // Tăng size chữ lên một chút cho đẹp
          ),

          // 4. Hiển thị Bio (Tiểu sử)
          // Kiểm tra nếu bio có dữ liệu mới hiện
          if (_user!.bio != null && _user!.bio!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                _user!.bio!,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),

          const SizedBox(height: 12),

          // 5. Nút Chỉnh sửa (Giữ nguyên)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    // Chuyển sang trang EditProfileScreen
                    // 'result' sẽ nhận về true nếu bấm Lưu, null nếu bấm Back
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(user: _user!),
                      ),
                    );

                    // Nếu có thay đổi (result == true), load lại dữ liệu để cập nhật giao diện
                    if (result == true) {
                      _loadData();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),

                  child: const Text(
                    "Chỉnh sửa trang cá nhân",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget con hiển thị cột số liệu (Giữ nguyên để dùng cho phần "Bài viết")
  Widget _buildStatColumn(int num, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          num.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13, // Giảm 1 size chữ  cho đỡ bị tràn dòng
              color: Colors.grey,
            ),
            textAlign: TextAlign.center, // Căn giữa text
            maxLines: 1, // Giới hạn 1 dòng
            overflow: TextOverflow.clip, // Cắt bớt nếu quá dài
          ),
        ),
      ],
    );
  }


  // ---------------------------------------------------------
  // Widget Lưới ảnh (Grid Post)
  Widget _buildPostGrid() {
    if (_userPosts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text("Chưa có bài viết nào"),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      itemCount: _userPosts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final post = _userPosts[index];

        // 👇 Logic xử lý hiển thị ảnh (Mạng hoặc Local)
        Widget imageWidget;
        if (post.imageUrl != null && post.imageUrl.isNotEmpty) {
          bool isNetworkImage =
              post.imageUrl.startsWith('http') ||
              post.imageUrl.startsWith('https');

          if (isNetworkImage) {
            imageWidget = Image.network(
              post.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
            );
          } else {
            imageWidget = Image.file(
              File(post.imageUrl),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
            );
          }
        } else {
          // Trường hợp không có ảnh -> Hiện text
          imageWidget = Container(
            color: Colors.blue[50],
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Text(
                post.caption ?? "",
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // 👇 BỌC TRONG INKWELL ĐỂ CLICK ĐƯỢC
        return InkWell(
          onTap: () {
            // Chuyển sang trang chi tiết
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(
                  post: post,
                  user: _user!, // Truyền user hiện tại vào
                ),
              ),
            );
          },
          child: Hero(
            // Hiệu ứng phóng to ảnh khi chuyển trang (Tùy chọn)
            tag: "post_${post.id}",
            child: imageWidget,
          ),
        );
      },
    );
  }
}
