import 'package:drift/drift.dart';

class Posts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userName => text().withLength(min: 1, max: 32)();
  TextColumn get imageUrl => text()();
  TextColumn get caption => text().nullable()();
  IntColumn get likes => integer().withDefault(const Constant(0))();
}