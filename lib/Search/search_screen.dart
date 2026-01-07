import 'package:flutter/material.dart';
import '../Database/app_database.dart';
import '../Profile/user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  // Bỏ TabController vì chỉ còn 1 chức năng duy nhất
  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    setState(() {
      _keyword = _searchController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm người dùng...', // Sửa hint text cho rõ ràng
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400]),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search, color: Colors.blueAccent),
              onPressed: _onSearch,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _keyword = value.trim();
            });
          },
          onSubmitted: (_) => _onSearch(),
        ),
        // Đã xóa phần bottom: TabBar
      ),
      // Body không cần TabBarView nữa, hiển thị trực tiếp kết quả User
      body: _keyword.isEmpty
          ? const Center(
        child: Text(
          "Nhập tên để tìm kiếm bạn bè",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      )
          : _buildUserResults(),
    );
  }

  Widget _buildUserResults() {
    return FutureBuilder<List<User>>(
      future: db.searchUsers(_keyword),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return const Center(
            child: Text(
              'Không tìm thấy người dùng nào',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blueAccent,
                // Hiển thị Avatar nếu có, không thì hiện chữ cái đầu
                backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                    ? NetworkImage(user.avatarUrl!) as ImageProvider
                    : null,
                child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                    ? Text(
                  user.userName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                )
                    : null,
              ),
              title: Text(
                user.fullName ?? user.userName, // Ưu tiên hiện tên đầy đủ
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                '@${user.userName}', // Hiện username bên dưới
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfileScreen(user: user),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
