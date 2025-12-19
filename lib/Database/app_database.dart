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

  // =========================
  // ===== ĐĂNG NHẬP =========
  // =========================

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
