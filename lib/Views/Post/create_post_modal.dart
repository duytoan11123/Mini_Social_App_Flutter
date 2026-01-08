import 'package:flutter/material.dart';
import '../../Controllers/post_controller.dart';
import '../../Controllers/auth_controller.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../Services/api_service.dart';

class CreatePostForm extends StatefulWidget {
  const CreatePostForm({super.key});

  @override
  State<CreatePostForm> createState() => _CreatePostFormState();
}

class _CreatePostFormState extends State<CreatePostForm> {
  File? _selectedImage;
  bool _isLoading = false;
  final _picker = ImagePicker();

  final TextEditingController _captionController = TextEditingController();
  var _fileButtonText = "Chọn Ảnh";

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      _fileButtonText = image.name;
    }
  }

  Future<void> _savePost() async {
    final currentUser = AuthController.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bạn chưa đăng nhập')));
      }
      return;
    }

    if (_selectedImage == null || _captionController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng chọn ảnh và nhập nội dung!")),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload Image to Server
      final imageUrl = await ApiService().uploadImage(_selectedImage!);

      // 2. Create Post
      await PostController.instance.createPost(
        imageUrl,
        _captionController.text.trim(),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Post error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Tạo Bài Đăng Mới',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Nút Chọn Ảnh
          ElevatedButton.icon(
            onPressed: () {
              _pickImage();
            },
            icon: const Icon(Icons.photo_library),
            label: Text(_fileButtonText),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 20),

          // Text Field cho Caption
          TextField(
            controller: _captionController,
            decoration: const InputDecoration(
              labelText: 'Viết chú thích (Caption) cho ảnh...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            minLines: 1,
          ),

          const SizedBox(height: 20),

          // Nút Đăng bài
          ElevatedButton(
            onPressed: () {
              _savePost();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Đăng Bài', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
