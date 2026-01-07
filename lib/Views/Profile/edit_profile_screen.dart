import 'dart:io'; // 👈 Bắt buộc có để dùng biến File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Thư viện chọn ảnh
import '../../Database/app_database.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  File? _selectedImage; // Biến này chỉ lưu File ảnh từ máy
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.user.fullName ?? widget.user.userName,
    );
    _bioController = TextEditingController(text: widget.user.bio ?? "");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // 👇 HÀM QUAN TRỌNG: CHỈ LẤY TỪ FILE
  Future<void> _pickImage() async {
    final picker = ImagePicker();

    // ImageSource.gallery = Chỉ mở thư viện/File trên máy
    // Nếu muốn chụp ảnh thì đổi thành ImageSource.camera
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path); // Lưu đường dẫn file
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    // Logic lưu đường dẫn ảnh
    String? finalAvatarUrl;

    // 1. Nếu người dùng vừa chọn ảnh mới -> Lấy đường dẫn file đó
    if (_selectedImage != null) {
      finalAvatarUrl = _selectedImage!.path;
    }
    // 2. Nếu không chọn gì -> Giữ nguyên đường dẫn cũ
    else {
      finalAvatarUrl = widget.user.avatarUrl;
    }

    User updatedUser = User(
      id: widget.user.id,
      userName: widget.user.userName,
      password: widget.user.password,
      avatarUrl: finalAvatarUrl, // Lưu đường dẫn file vào DB
      fullName: _nameController.text.trim(),
      bio: _bioController.text.trim(),
    );

    await db.updateUser(updatedUser);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logic hiển thị ảnh (Preview)
    ImageProvider? imageProvider;

    // Ưu tiên 1: Hiển thị ảnh File vừa chọn từ máy
    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    }
    // Ưu tiên 2: Hiển thị ảnh cũ đã lưu trong DB
    else if (widget.user.avatarUrl != null &&
        widget.user.avatarUrl!.isNotEmpty) {
      // Vì dữ liệu cũ có thể là Link mạng hoặc File, ta check cả 2 cho chắc
      if (widget.user.avatarUrl!.startsWith('http')) {
        imageProvider = NetworkImage(widget.user.avatarUrl!);
      } else {
        // Đây là trường hợp hiển thị File đã lưu từ lần trước
        imageProvider = FileImage(File(widget.user.avatarUrl!));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chỉnh sửa trang cá nhân"),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.check, color: Colors.blue),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Avatar
            Center(
              child: GestureDetector(
                onTap: _pickImage, // Bấm vào gọi hàm chọn File
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 20,
                        ), // Icon thư viện ảnh
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Chạm để chọn ảnh từ thư viện",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 30),

            // TextField Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Tên hiển thị",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            // TextField Bio
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Tiểu sử",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info_outline),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
