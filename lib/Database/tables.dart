import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userName => text().withLength(min: 3, max: 20)();
  TextColumn get password => text()();
  TextColumn get avatarUrl => text().nullable()();
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
