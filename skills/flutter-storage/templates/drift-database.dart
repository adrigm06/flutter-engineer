// Drift database template — complete setup with DAOs, migrations, WAL mode
// Replace [AppName] and table names as needed
// Run: dart run build_runner build --delete-conflicting-outputs

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database.g.dart';

// ===========================================================================
// TABLES
// ===========================================================================

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().unique()();
  TextColumn get email => text()();
  TextColumn get displayName => text()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().unique()();
  TextColumn get title => text()();
  RealColumn get price => real()();
  TextColumn get category => text()();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get taskType => text()();
  TextColumn get payload => text()();  // JSON
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  BoolColumn get isProcessing => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ===========================================================================
// DATABASE
// ===========================================================================

@DriftDatabase(tables: [Users, Products, SyncQueue], daos: [UsersDao, ProductsDao, SyncQueueDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  // In-memory database for tests
  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 3;  // Increment on every schema change

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // ── Migration v1 → v2: add isSynced to users
      if (from < 2) {
        await m.addColumn(users, users.isSynced);
      }
      // ── Migration v2 → v3: add SyncQueue table
      if (from < 3) {
        await m.createTable(syncQueue);
      }
      // Each version gets its own if block — never use else-if
    },
    beforeOpen: (OpeningDetails details) async {
      if (details.wasCreated) {
        // Seed data if needed
      }
      // Enable WAL mode for better concurrent read performance
      await customStatement('PRAGMA journal_mode=WAL');
      // Enable foreign keys
      await customStatement('PRAGMA foreign_keys=ON');
    },
  );
}

// ===========================================================================
// DATABASE CONNECTION
// ===========================================================================

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.sqlite'));

    // Use background isolate for better performance on large databases
    return NativeDatabase.createInBackground(file);
  });
}

// ===========================================================================
// PROVIDERS
// ===========================================================================

@riverpod
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  // Close database when provider is disposed
  ref.onDispose(db.close);
  return db;
}

// ===========================================================================
// USERS DAO
// ===========================================================================

@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  Stream<List<User>> watchAll() => select(users).watch();

  Future<List<User>> getAll() => select(users).get();

  Future<User?> getByRemoteId(String remoteId) =>
      (select(users)..where((u) => u.remoteId.equals(remoteId)))
          .getSingleOrNull();

  Future<int> upsert(UsersCompanion user) =>
      into(users).insertOnConflictUpdate(user);

  Future<void> upsertAll(List<UsersCompanion> userList) async {
    await batch((batch) => batch.insertAllOnConflictUpdate(users, userList));
  }

  Future<bool> update(UsersCompanion user) =>
      update(users).replace(user);

  Future<int> deleteByRemoteId(String remoteId) =>
      (delete(users)..where((u) => u.remoteId.equals(remoteId))).go();

  Future<List<User>> getUnsynced() =>
      (select(users)..where((u) => u.isSynced.equals(false))).get();

  Future<void> markSynced(int localId) => (update(users)
        ..where((u) => u.id.equals(localId)))
      .write(const UsersCompanion(isSynced: Value(true)));
}

// ===========================================================================
// PRODUCTS DAO
// ===========================================================================

@DriftAccessor(tables: [Products])
class ProductsDao extends DatabaseAccessor<AppDatabase> with _$ProductsDaoMixin {
  ProductsDao(super.db);

  Stream<List<Product>> watchByCategory(String category) =>
      (select(products)..where((p) => p.category.equals(category))).watch();

  Future<List<Product>> searchByTitle(String query) =>
      (select(products)..where((p) => p.title.contains(query))).get();

  Future<void> replaceAll(List<ProductsCompanion> newProducts) async {
    await transaction(() async {
      await delete(products).go();
      await batch((b) => b.insertAll(products, newProducts));
    });
  }
}

// ===========================================================================
// SYNC QUEUE DAO
// ===========================================================================

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase> with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Future<int> enqueue(SyncQueueCompanion task) => into(syncQueue).insert(task);

  Future<List<SyncQueueEntry>> getPending({int limit = 10}) =>
      (select(syncQueue)
            ..where((t) => t.isProcessing.equals(false))
            ..where((t) =>
                t.nextRetryAt.isNull() |
                t.nextRetryAt.isSmallerOrEqualValue(DateTime.now()))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
            ..limit(limit))
          .get();

  Future<void> incrementRetry(int id, {required DateTime nextRetryAt}) =>
      (update(syncQueue)..where((t) => t.id.equals(id))).write(
        SyncQueueCompanion(
          retryCount: Value(
            (select(syncQueue)..where((t) => t.id.equals(id)))
                .map((r) => r.retryCount)
                .first as int + 1,
          ),
          nextRetryAt: Value(nextRetryAt),
        ),
      );

  Future<int> remove(int id) =>
      (delete(syncQueue)..where((t) => t.id.equals(id))).go();
}
