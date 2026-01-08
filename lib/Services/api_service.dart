import 'package:dio/dio.dart';
import 'dart:io';
import '../Models/user_model.dart';
import '../Models/post_model.dart';
import '../Models/comment_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Use 10.0.2.2 for Android Emulator to access localhost
  // Use localhost for iOS Simulator
  // Update this IP if testing on physical device
  final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: 'https://flutter-demo-api.onrender.com/api',
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 3),
          ),
        )
        ..interceptors.add(
          LogInterceptor(
            requestBody: true,
            responseBody: true,
            logPrint: (obj) => print("API LOG: $obj"),
          ),
        );

  // --- AUTH ---
  Future<UserModel> register(
    String username,
    String password,
    String email,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {'username': username, 'password': password, 'email': email},
      );
      return UserModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      return UserModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // --- POSTS ---
  Future<List<PostModel>> getPosts({String? userId}) async {
    try {
      final queryParams = userId != null ? {'authorId': userId} : null;
      final response = await _dio.get('/posts', queryParameters: queryParams);
      return (response.data as List).map((e) => PostModel.fromJson(e)).toList();
    } catch (e) {
      print('Error getting posts: $e');
      return [];
    }
  }

  Future<PostModel> createPost(
    String authorId,
    String imageUrl,
    String? caption,
  ) async {
    try {
      final response = await _dio.post(
        '/posts',
        data: {'authorId': authorId, 'imageUrl': imageUrl, 'caption': caption},
      );
      return PostModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _dio.delete('/posts/$postId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<PostModel> updatePost(String postId, String caption) async {
    try {
      final response = await _dio.put(
        '/posts/$postId',
        data: {'caption': caption},
      );
      return PostModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // --- COMMENTS ---
  Future<List<CommentModel>> getComments(
    String postId, {
    String? userId,
  }) async {
    try {
      final queryParams = userId != null ? {'userId': userId} : null;
      final response = await _dio.get(
        '/posts/$postId/comments',
        queryParameters: queryParams,
      );
      return (response.data as List)
          .map((e) => CommentModel.fromJson(e))
          .toList();
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }

  Future<CommentModel> addComment(
    String postId,
    String userId,
    String content, {
    String? parentId,
  }) async {
    try {
      final response = await _dio.post(
        '/posts/$postId/comments',
        data: {'userId': userId, 'content': content, 'parentId': parentId},
      );
      return CommentModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // --- LIKES ---
  Future<bool> toggleLike(String postId, String userId) async {
    try {
      final response = await _dio.post(
        '/posts/$postId/like',
        data: {'userId': userId},
      );
      return response.data['liked'] ?? false;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> toggleCommentLike(String commentId, String userId) async {
    try {
      final response = await _dio.post(
        '/posts/comments/$commentId/like',
        data: {'userId': userId},
      );
      return response.data['liked'] ?? false;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> hasLiked(String postId, String userId) async {
    try {
      final response = await _dio.get(
        '/posts/$postId/like',
        queryParameters: {'userId': userId},
      );
      return response.data['liked'] ?? false;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // --- USER / PROFILE ---
  Future<List<UserModel>> searchUsers(String keyword) async {
    try {
      final response = await _dio.get(
        '/users/search',
        queryParameters: {'q': keyword},
      );
      return (response.data as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel?> getUserProfile(
    String userId, {
    String? requesterId,
  }) async {
    try {
      final queryParams = requesterId != null
          ? {'requesterId': requesterId}
          : null;
      final response = await _dio.get(
        '/users/$userId',
        queryParameters: queryParams,
      );
      return UserModel.fromJson(response.data);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<String> uploadImage(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dio.post('/upload', data: formData);
      return response.data['fullUrl'] ?? response.data['filePath'];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserModel> updateProfile(
    String userId, {
    String? fullName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['fullName'] = fullName;
      if (bio != null) data['bio'] = bio;
      if (avatarUrl != null) data['avatarUrl'] = avatarUrl;

      final response = await _dio.put('/users/$userId', data: data);
      return UserModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Retry toggleFollow with userId param

  Future<void> toggleFollowUser(
    String targetUserId,
    String currentUserId,
  ) async {
    try {
      await _dio.post(
        '/users/$targetUserId/follow',
        data: {'followerId': currentUserId},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        return error.response?.data['message'] ?? 'Server error';
      }
      return 'Connection error';
    }
    return error.toString();
  }
}
