import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'tables.dart';

part 'app_database.g.dart';

late AppDatabase db;
int? currentUserId;

@DriftDatabase(tables: [Posts, Users, Comments, CommentReactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

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

  // =========================
  // ===== BÌNH LUẬN =========
  // =========================

  Future<int> insertComment(CommentsCompanion entry) {
    return into(comments).insert(entry);
  }

  Future<int> deleteComment(int id) {
    return (delete(comments)..where((c) => c.id.equals(id))).go();
  }

  Future<int> getCommentCount(int postId) async {
    final count = await (select(comments)..where((c) => c.postId.equals(postId))).get();
    return count.length;
  }

  // Lấy comment gốc (không phải reply)
  Stream<List<CommentWithUser>> watchCommentsForPost(int postId) {
    final query = select(comments).join([
      leftOuterJoin(users, users.id.equalsExp(comments.userId)),
    ])..where(comments.postId.equals(postId) & comments.parentId.isNull())
      ..orderBy([OrderingTerm(expression: comments.createdAt, mode: OrderingMode.asc)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return CommentWithUser(
          comment: row.readTable(comments),
          user: row.readTable(users),
        );
      }).toList();
    });
  }

  // Lấy replies của một comment
  Stream<List<CommentWithUser>> watchRepliesForComment(int parentId) {
    final query = select(comments).join([
      leftOuterJoin(users, users.id.equalsExp(comments.userId)),
    ])..where(comments.parentId.equals(parentId))
      ..orderBy([OrderingTerm(expression: comments.createdAt, mode: OrderingMode.asc)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return CommentWithUser(
          comment: row.readTable(comments),
          user: row.readTable(users),
        );
      }).toList();
    });
  }

  // Đếm số reply của một comment
  Future<int> getReplyCount(int parentId) async {
    final count = await (select(comments)..where((c) => c.parentId.equals(parentId))).get();
    return count.length;
  }

  Future<List<CommentWithUser>> getRecentComments(int postId, {int limit = 2}) async {
    final query = select(comments).join([
      leftOuterJoin(users, users.id.equalsExp(comments.userId)),
    ])..where(comments.postId.equals(postId) & comments.parentId.isNull())
      ..orderBy([OrderingTerm(expression: comments.createdAt, mode: OrderingMode.desc)])
      ..limit(limit);

    final rows = await query.get();
    return rows.map((row) {
      return CommentWithUser(
        comment: row.readTable(comments),
        user: row.readTable(users),
      );
    }).toList().reversed.toList();
  }

  // =========================
  // ===== REACTIONS =========
  // =========================

  Future<void> toggleReaction(int commentId, int userId, String reaction) async {
    final existing = await (select(commentReactions)
      ..where((r) => r.commentId.equals(commentId) & r.userId.equals(userId)))
      .getSingleOrNull();

    if (existing != null) {
      if (existing.reaction == reaction) {
        // Xóa reaction nếu đã chọn cùng loại
        await (delete(commentReactions)..where((r) => r.id.equals(existing.id))).go();
      } else {
        // Đổi sang reaction khác
        await (update(commentReactions)..where((r) => r.id.equals(existing.id)))
          .write(CommentReactionsCompanion(reaction: Value(reaction)));
      }
    } else {
      // Thêm reaction mới
      await into(commentReactions).insert(CommentReactionsCompanion(
        commentId: Value(commentId),
        userId: Value(userId),
        reaction: Value(reaction),
      ));
    }
  }

  Future<String?> getUserReaction(int commentId, int userId) async {
    final result = await (select(commentReactions)
      ..where((r) => r.commentId.equals(commentId) & r.userId.equals(userId)))
      .getSingleOrNull();
    return result?.reaction;
  }

  Stream<List<ReactionCount>> watchReactionsForComment(int commentId) {
    final query = selectOnly(commentReactions)
      ..addColumns([commentReactions.reaction, commentReactions.id.count()])
      ..where(commentReactions.commentId.equals(commentId))
      ..groupBy([commentReactions.reaction]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return ReactionCount(
          reaction: row.read(commentReactions.reaction)!,
          count: row.read(commentReactions.id.count())!,
        );
      }).toList();
    });
  }

  Future<int> getTotalReactionCount(int commentId) async {
    final result = await (select(commentReactions)
      ..where((r) => r.commentId.equals(commentId))).get();
    return result.length;
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

class CommentWithUser {
  final Comment comment;
  final User user;

  CommentWithUser({required this.comment, required this.user});
}

class ReactionCount {
  final String reaction;
  final int count;

  ReactionCount({required this.reaction, required this.count});
}
