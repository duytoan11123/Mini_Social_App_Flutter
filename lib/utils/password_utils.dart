import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordUtils {
  //  Thêm Salt
  static const String _salt = 'flutter_app_salt_2025';

  static String hash(String password) {
    final bytes = utf8.encode(password + _salt);
    return sha256.convert(bytes).toString();
  }
}
