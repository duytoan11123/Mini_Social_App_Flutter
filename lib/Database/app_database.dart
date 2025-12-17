import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'tables.dart'; // Import các bảng vừa tạo

// Phần này báo cho Drift biết các bảng cần xử lý
part 'app_database.g.dart'; // Tệp sẽ được tạo tự động bởi build_runner


late AppDatabase db;
// Định nghĩa lớp Database
@DriftDatabase(tables: [Posts, Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  // --- Các truy vấn (DAO Methods) ---

  // 1. Lấy tất cả bài đăng (Observable: tự cập nhật khi DB thay đổi)
  Stream<List<Post>> watchAllPosts() {
    return select(posts).watch();
  }

  // 2. Thêm bài đăng mới
  Future<int> insertPost(PostsCompanion entry) {
    return into(posts).insert(entry);
  }

  // 3. Xóa bài đăng
  Future<int> deletePost(int id) {
    return (delete(posts)..where((t) => t.id.equals(id))).go();
  }

  //Thêm người dùng mới
  Future<int> insertUser(UsersCompanion entry) {
    return into(users).insert(entry);
  }

  //Lấy tất cả người dùng
  Future<List<User>> getAllUsers() {
    return select(users).get();
  }

  //Lấy người dùng theo ID
  Future<User?> getUserById(int id) {
    return (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();
  }
  //Lấy Post cùng với thông tin User
  Stream<List<PostWithUser>> watchPostsWithUsers() {
    final query = select(posts).join([
      leftOuterJoin(users, users.id.equalsExp(posts.authorId)),
    ]);
    query.orderBy([OrderingTerm(expression: posts.createdAt, mode: OrderingMode.desc)]);
    final results = query.watch();

    return results.map((rows) {
      return rows.map((row) {
        return PostWithUser(
          post: row.readTable(posts),
          user: row.readTable(users)
        );
      }).toList();
    });
  }
}

// Hàm kết nối cơ sở dữ liệu SQLite
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Lấy thư mục lưu trữ ứng dụng
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    
    // Trả về kết nối DB
    return NativeDatabase.createInBackground(file);
  });
}

void setupDatabase() {
  db = AppDatabase();
}

class PostWithUser {
  final Post post;
  final User user;

  PostWithUser({required this.post, required this.user});
}