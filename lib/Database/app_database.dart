import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'tables.dart';

part 'app_database.g.dart';

late AppDatabase db;
int? currentUserId;

@DriftDatabase(tables: [Posts, Users, Comments, CommentReactions, PostLikes, Follows])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 9;

  /// Đăng ký tài khoản mới
  Future<User?> register(
    String username,
    String password, {
    String? email,
  }) async {
    final existingUser = await (select(
      users,
    )..where((u) => u.userName.equals(username))).getSingleOrNull();

    if (existingUser != null) {
      return null;
    }

    final newEntry = UsersCompanion.insert(
      userName: username,
      password: password,
      email: Value(email),
      createdAt: Value(DateTime.now()),
    );

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
        for (final table in allTables) {
          await m.deleteTable(table.actualTableName);
        }
        await m.createAll();
      },
    );
  }

  Future<User?> login(String username, String password) async {
    final query = select(users)
      ..where((u) => u.userName.equals(username) & u.password.equals(password));

    return await query.getSingleOrNull();
  }

  // =========================
  // ===== POSTS & USERS =====
  // =========================

  Stream<List<Post>> watchAllPosts() {
    return select(posts).watch();
  }

  Future<int> insertPost(PostsCompanion entry) {
    return into(posts).insert(entry);
  }

  Future<void> deletePost(int id) {
    return transaction(() async {
      await (delete(postLikes)..where((t) => t.postId.equals(id))).go();

      final commentsOfPost = await (select(
        comments,
      )..where((t) => t.postId.equals(id))).get();

      for (var c in commentsOfPost) {
        await (delete(
          commentReactions,
        )..where((r) => r.commentId.equals(c.id))).go();
        await (delete(comments)..where((t) => t.id.equals(c.id))).go();
      }

      await (delete(posts)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<bool> updatePost(Post post) {
    return update(posts).replace(post);
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
  // ===== BÌNH LUẬN (Code từ nhánh dev) =========
  // =========================

  Future<int> insertComment(CommentsCompanion entry) {
    return into(comments).insert(entry);
  }

  Future<int> deleteComment(int id) {
    return (delete(comments)..where((c) => c.id.equals(id))).go();
  }

  Future<int> getCommentCount(int postId) async {
    final count = await (select(
      comments,
    )..where((c) => c.postId.equals(postId))).get();
    return count.length;
  }

  // Lấy comment gốc (không phải reply)
  Stream<List<CommentWithUser>> watchCommentsForPost(int postId) {
    final query =
        select(
            comments,
          ).join([leftOuterJoin(users, users.id.equalsExp(comments.userId))])
          ..where(comments.postId.equals(postId) & comments.parentId.isNull())
          ..orderBy([
            OrderingTerm(
              expression: comments.createdAt,
              mode: OrderingMode.asc,
            ),
          ]);

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
    final query =
        select(
            comments,
          ).join([leftOuterJoin(users, users.id.equalsExp(comments.userId))])
          ..where(comments.parentId.equals(parentId))
          ..orderBy([
            OrderingTerm(
              expression: comments.createdAt,
              mode: OrderingMode.asc,
            ),
          ]);

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
    final count = await (select(
      comments,
    )..where((c) => c.parentId.equals(parentId))).get();
    return count.length;
  }

  Future<List<CommentWithUser>> getRecentComments(
    int postId, {
    int limit = 2,
  }) async {
    final query =
        select(
            comments,
          ).join([leftOuterJoin(users, users.id.equalsExp(comments.userId))])
          ..where(comments.postId.equals(postId) & comments.parentId.isNull())
          ..orderBy([
            OrderingTerm(
              expression: comments.createdAt,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(limit);

    final rows = await query.get();
    return rows
        .map((row) {
          return CommentWithUser(
            comment: row.readTable(comments),
            user: row.readTable(users),
          );
        })
        .toList()
        .reversed
        .toList();
  }

  // =========================
  // ===== REACTIONS (Code từ nhánh dev) =========
  // =========================

  Future<void> toggleReaction(
    int commentId,
    int userId,
    String reaction,
  ) async {
    final existing =
        await (select(commentReactions)..where(
              (r) => r.commentId.equals(commentId) & r.userId.equals(userId),
            ))
            .getSingleOrNull();

    if (existing != null) {
      if (existing.reaction == reaction) {
        // Xóa reaction nếu đã chọn cùng loại
        await (delete(
          commentReactions,
        )..where((r) => r.id.equals(existing.id))).go();
      } else {
        // Đổi sang reaction khác
        await (update(commentReactions)..where((r) => r.id.equals(existing.id)))
            .write(CommentReactionsCompanion(reaction: Value(reaction)));
      }
    } else {
      // Thêm reaction mới
      await into(commentReactions).insert(
        CommentReactionsCompanion(
          commentId: Value(commentId),
          userId: Value(userId),
          reaction: Value(reaction),
        ),
      );
    }
  }

  Future<String?> getUserReaction(int commentId, int userId) async {
    final result =
        await (select(commentReactions)..where(
              (r) => r.commentId.equals(commentId) & r.userId.equals(userId),
            ))
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
    final result = await (select(
      commentReactions,
    )..where((r) => r.commentId.equals(commentId))).get();
    return result.length;
  }

  // =========================
  // ===== PROFILE (Code của bạn) =========
  // =========================

  /// Lấy tất cả bài viết của một người dùng cụ thể
  Future<List<Post>> getPostsByUserId(int userId) {
    return (select(posts)..where((t) => t.authorId.equals(userId))).get();
  }

  /// Cập nhật thông tin User
  Future<bool> updateUser(User user) {
    return update(users).replace(user);
  }

  // ==========================
  // ====== FOLLOW SYSTEM =====
  // ==========================

  // 1. Kiểm tra trạng thái follow
  Future<bool> isFollowing(int followerId, int followingId) async {
    final result = await (select(follows)
      ..where((t) =>
      t.followerId.equals(followerId) & t.followingId.equals(followingId)))
        .getSingleOrNull();
    return result != null;
  }

  // 2. Toggle Follow (Bấm nút Follow/Unfollow)
  Future<void> toggleFollow(int followerId, int followingId) async {
    final isAlreadyFollowing = await isFollowing(followerId, followingId);

    if (isAlreadyFollowing) {
      // Đang follow -> Xóa (Unfollow)
      await (delete(follows)
        ..where((t) =>
        t.followerId.equals(followerId) &
        t.followingId.equals(followingId)))
          .go();
    } else {
      // Chưa follow -> Thêm mới
      await into(follows).insert(FollowsCompanion(
        followerId: Value(followerId),
        followingId: Value(followingId),
      ));
    }
  }

  // 3. Đếm số người đang theo dõi mình (Followers Count)
  Stream<int> watchFollowersCount(int userId) {
    final query = selectOnly(follows)
      ..addColumns([follows.id.count()])
      ..where(follows.followingId.equals(userId));

    return query.map((row) => row.read(follows.id.count())!).watchSingle();
  }

  // 4. Đếm số người mình đang theo dõi (Following Count)
  Stream<int> watchFollowingCount(int userId) {
    final query = selectOnly(follows)
      ..addColumns([follows.id.count()])
      ..where(follows.followerId.equals(userId));

    return query.map((row) => row.read(follows.id.count())!).watchSingle();
  }


  // =========================
  // ===== POST LIKES =========
  // =========================

  Future<bool> hasUserLikedPost(int postId, int userId) async {
    final entry =
        await (select(postLikes)
              ..where((t) => t.postId.equals(postId) & t.userId.equals(userId)))
            .getSingleOrNull();
    return entry != null;
  }

  Future<void> togglePostLike(int postId, int userId) async {
    return transaction(() async {
      final existing =
          await (select(postLikes)..where(
                (t) => t.postId.equals(postId) & t.userId.equals(userId),
              ))
              .getSingleOrNull();

      if (existing != null) {
        // Unlike: Xóa khỏi bảng PostLikes và giảm count trong Posts
        await (delete(postLikes)..where((t) => t.id.equals(existing.id))).go();

        final post = await (select(
          posts,
        )..where((t) => t.id.equals(postId))).getSingle();
        await (update(posts)..where((t) => t.id.equals(postId))).write(
          PostsCompanion(likes: Value(post.likes > 0 ? post.likes - 1 : 0)),
        );
      } else {
        // Like: Thêm vào bảng PostLikes và tăng count trong Posts
        await into(postLikes).insert(
          PostLikesCompanion(postId: Value(postId), userId: Value(userId)),
        );

        final post = await (select(
          posts,
        )..where((t) => t.id.equals(postId))).getSingle();
        await (update(posts)..where((t) => t.id.equals(postId))).write(
          PostsCompanion(likes: Value(post.likes + 1)),
        );
      }
    });
  }

  // =========================
  // ===== TÌM KIẾM (SEARCH) =
  // =========================

  /// Tìm kiếm người dùng theo tên (Username)
  Future<List<User>> searchUsers(String keyword) {
    if(keyword.trim().isEmpty){
      return Future.value([]);
    }

    return (select(users)
      ..where((u) => u.userName.lower().like('%${keyword.toLowerCase()}%'))
    ).get();
  }

  /// Tìm kiếm bài viết theo nội dung
  Stream<List<PostWithUser>> searchPosts(String keyword) {
    // Nếu từ khóa rỗng, trả về list rỗng
    if (keyword.trim().isEmpty) {
      return Stream.value([]);
    }

    final query = select(posts).join([
      innerJoin(users, users.id.equalsExp(posts.authorId)), // Dùng innerJoin để đảm bảo lấy được user
    ]);

    // Thêm điều kiện tìm kiếm theo nội dung
    query.where(posts.caption.lower().like('%${keyword.toLowerCase()}%'));

    // Sắp xếp bài mới nhất lên đầu
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

// =========================
// ===== CÁC CLASS PHỤ TRỢ
// =========================

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
