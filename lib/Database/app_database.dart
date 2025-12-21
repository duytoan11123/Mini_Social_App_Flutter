import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'tables.dart';

part 'app_database.g.dart';

late AppDatabase db;
int? currentUserId;

@DriftDatabase(tables: [Posts, Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  /// Đăng ký tài khoản mới
  /// Trả về User object nếu thành công
  /// Trả về null nếu username đã tồn tại
  Future<User?> register(
    String username,
    String password, {
    String? email,
  }) async {
    // 1. Kiểm tra xem username đã tồn tại chưa
    final existingUser = await (select(
      users,
    )..where((u) => u.userName.equals(username))).getSingleOrNull();

    if (existingUser != null) {
      return null; // Username đã bị trùng
    }

    // 2. Chuẩn bị dữ liệu để chèn
    // Sử dụng UsersCompanion.insert để Drift tự động xử lý các trường bắt buộc/tùy chọn
    final newEntry = UsersCompanion.insert(
      userName: username,
      password: password,
      email: Value(email), // Value(null) nếu không có email
      createdAt: Value(DateTime.now()), // Gán thời gian hiện tại
    );

    // 3. Chèn vào DB và trả về dòng dữ liệu vừa tạo (bao gồm cả ID tự tăng)
    return await into(users).insertReturning(newEntry);
  }
  // =========================
  // ===== ĐĂNG NHẬP =========
  // =========================

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Code "đập đi xây lại" cho môi trường Dev
        for (final table in allTables) {
          await m.deleteTable(table.actualTableName);
        }
        await m.createAll();
      },
    );
  }

  /// Kiểm tra username + password
  /// Chỉ dùng cho đăng nhập – KHÔNG tạo user
  Future<User?> login(String username, String password) async {
    final query = select(users)
      ..where((u) => u.userName.equals(username) & u.password.equals(password));

    return await query.getSingleOrNull();
  }

  // =========================
  // ===== CODE CŨ GIỮ NGUYÊN
  // =========================

  Stream<List<Post>> watchAllPosts() {
    return select(posts).watch();
  }

  Future<int> insertPost(PostsCompanion entry) {
    return into(posts).insert(entry);
  }

  Future<int> deletePost(int id) {
    return (delete(posts)..where((t) => t.id.equals(id))).go();
  }

  Future<int> insertUser(UsersCompanion entry) {
    return into(users).insert(entry);
  }

  Future<List<User>> getAllUsers() {
    return select(users).get();
  }

  Future<User?> getUserById(int id) {
    return (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();
  }

  Stream<List<PostWithUser>> watchPostsWithUsers() {
    final query = select(
      posts,
    ).join([leftOuterJoin(users, users.id.equalsExp(posts.authorId))]);

    query.orderBy([
      OrderingTerm(expression: posts.createdAt, mode: OrderingMode.desc),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return PostWithUser(
          post: row.readTable(posts),
          user: row.readTable(users),
        );
      }).toList();
    });
  }

  /// Lấy tất cả bài viết của một người dùng cụ thể
  Future<List<Post>> getPostsByUserId(int userId) {
    return (select(posts)..where((t) => t.authorId.equals(userId))).get();
  }

  Future<bool> updateUser(User user) {
    return update(users).replace(user);
  }
}
// =========================
// ===== KẾT NỐI DATABASE
// =========================

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

Future<void> setupDatabase() async {
  db = AppDatabase();
}

class PostWithUser {
  final Post post;
  final User user;

  PostWithUser({required this.post, required this.user});
}
