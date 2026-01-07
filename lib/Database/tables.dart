import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userName => text().withLength(min: 3, max: 20).unique()();
  TextColumn get password => text()();
  TextColumn get email => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  TextColumn get fullName => text().nullable()();
  TextColumn get bio => text().nullable()();
}

class Posts extends Table {
  IntColumn get id => integer().autoIncrement()();
  //Liên kết với bảng Users
  IntColumn get authorId => integer().references(Users, #id)();
  TextColumn get imageUrl => text()();
  TextColumn get caption => text().nullable()();
  IntColumn get likes => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Comments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get postId => integer().references(Posts, #id)();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get content => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get parentId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Reactions cho bình luận: 👍❤️😆😮😢😠
class CommentReactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get commentId => integer().references(Comments, #id)();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get reaction => text()(); // like, love, haha, wow, sad, angry
}

class PostLikes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get postId => integer().references(Posts, #id)();
  IntColumn get userId => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Bảng lưu quan hệ theo dõi
class Follows extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Người đi theo dõi (Me)
  IntColumn get followerId => integer().references(Users, #id)();
  // Người được theo dõi (You)
  IntColumn get followingId => integer().references(Users, #id)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // Một người chỉ theo dõi một người khác 1 lần duy nhất
  @override
  List<Set<Column>> get uniqueKeys => [{followerId, followingId}];
}