
import 'package:flutter/material.dart';
class CreatePostForm extends StatefulWidget {
  const CreatePostForm({super.key});

  @override
  State<CreatePostForm> createState() => _CreatePostFormState();
}

class _CreatePostFormState extends State<CreatePostForm> {
  final TextEditingController _captionController = TextEditingController();

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

          // Nút Giả lập chọn ảnh
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Xử lý chức năng chọn ảnh thực tế (Image Picker)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng chọn ảnh (Image Picker) chưa được cài đặt!')),
              );
            },
            icon: const Icon(Icons.photo_library),
            label: const Text('Chọn Ảnh'),
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
              // TODO: Xử lý chức năng đăng bài thực tế
              final caption = _captionController.text;
              Navigator.pop(context); // Đóng modal
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã giả lập đăng bài với Caption: "$caption"')),
              );
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