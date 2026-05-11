---
name: flutter-storage
description: >
  Lead authority for Flutter local storage decisions. Use when choosing between
  Drift, Isar, Hive CE, flutter_secure_storage, shared_preferences, or designing
  database schemas, migrations, and encrypted storage.
---

# Flutter Storage Skill

## Purpose

Select, configure, and implement the right local storage solution for each data need —
from simple key-value preferences to encrypted relational databases and offline-first
document stores.

## Scope and authority

Lead authority for:

- storage solution selection (Drift, Isar, Hive CE, SharedPreferences, flutter_secure_storage)
- database schema design (Drift)
- migration strategy (Drift migrations)
- encrypted storage for sensitive data
- storage layer architecture (Services wrapping storage)
- data model transformation (DB model → domain model)

Defers to:

- `flutter-security` for security requirements on stored data (always consulted for sensitive data)
- `flutter-offline-first` for full offline sync architecture
- `flutter-networking` for remote data fetching feeding storage

---

## Decision engine workflow

1. Classify data sensitivity (public / semi-sensitive / sensitive / regulated).
2. Classify data type (key-value / relational / document / binary).
3. Classify query complexity and volume.
4. Select storage solution.
5. Design service layer wrapping storage.
6. Define migration strategy if schema can evolve.

---

## Storage selection matrix (reference DECISION_MATRIX.md)

| Use case | Solution | Encryption |
|---|---|---|
| Simple preferences (theme, settings) | shared_preferences | None (not sensitive) |
| Auth tokens, API keys | flutter_secure_storage | Keychain/Keystore native |
| Relational data (offline-first) | Drift | Optional: SQLCipher |
| Document/JSON storage | Isar (community) | Optional: AES |
| High-perf key-value | Hive CE | Optional: HiveAesCipher |
| Regulated data (medical, financial) | Drift + SQLCipher | Required |
| File/binary storage | path_provider + dart:io | As needed |

---

## Drift (SQLite) — recommended for relational offline-first

### Dependency setup

```yaml
dependencies:
  drift: ^2.x
  sqlite3_flutter_libs: ^0.x
  path_provider: ^2.x
  path: ^1.x

dev_dependencies:
  drift_dev: ^2.x
  build_runner: ^2.x
```

### Table definition

```dart
// data/local/tables/todos_table.dart
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

### Database definition

```dart
// data/local/app_database.dart
@DriftDatabase(tables: [Todos])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(todos, todos.isSynced);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(path.join(dbFolder.path, 'app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
```

### Data Access Object (DAO) pattern

```dart
// data/local/daos/todos_dao.dart
@DriftAccessor(tables: [Todos])
class TodosDao extends DatabaseAccessor<AppDatabase> with _$TodosDaoMixin {
  TodosDao(super.db);

  Stream<List<Todo>> watchAllTodos() => select(todos).watch();

  Future<List<Todo>> getAllTodos() => select(todos).get();

  Future<int> insertTodo(TodosCompanion todo) =>
      into(todos).insert(todo);

  Future<bool> updateTodo(TodosCompanion todo) =>
      update(todos).replace(todo);

  Future<int> deleteTodo(int id) =>
      (delete(todos)..where((t) => t.id.equals(id))).go();

  Future<List<Todo>> getUnsyncedTodos() =>
      (select(todos)..where((t) => t.isSynced.equals(false))).get();
}
```

### Service wrapper (repository calls this, not Drift directly)

```dart
// data/local/datasources/todos_local_datasource.dart
class TodosLocalDataSource {
  TodosLocalDataSource(this._dao);
  final TodosDao _dao;

  Stream<List<TodoDbModel>> watchTodos() =>
      _dao.watchAllTodos().map((rows) => rows.map(TodoDbModel.fromRow).toList());

  Future<void> insertTodo(TodoDbModel model) =>
      _dao.insertTodo(model.toCompanion());

  Future<void> markSynced(int id) =>
      _dao.updateTodo(TodosCompanion(id: Value(id), isSynced: const Value(true)));
}
```

---

## Isar (community edition) — document store

```dart
@collection
class CachedProduct {
  Id id = Isar.autoIncrement;

  late String remoteId;
  late String title;
  late double price;
  late DateTime cachedAt;

  @Index(type: IndexType.value)
  late String category;
}

// Repository usage:
final isar = await Isar.open([CachedProductSchema]);
await isar.writeTxn(() async {
  await isar.cachedProducts.put(product);
});

final products = await isar.cachedProducts
    .filter()
    .categoryEqualTo('electronics')
    .findAll();
```

---

## flutter_secure_storage — sensitive data

```dart
// core/storage/secure_storage.dart
class SecureTokenStorage {
  const SecureTokenStorage(this._storage);
  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() =>
      _storage.read(key: _accessTokenKey);

  Future<void> clearAll() => _storage.deleteAll();
}
```

---

## Hive CE — high-performance key-value

```dart
// Only for non-sensitive structured data with simple queries
@HiveType(typeId: 0)
class UserPreferences extends HiveObject {
  @HiveField(0)
  late String theme;

  @HiveField(1)
  late bool notificationsEnabled;
}

// Usage
final box = await Hive.openBox<UserPreferences>('preferences');
final prefs = box.get('user') ?? UserPreferences()
  ..theme = 'dark'
  ..notificationsEnabled = true;
await prefs.save();
```

---

## Migration strategy for Drift

```dart
// Always version your schema — never drop tables in production
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    // Explicit per-version upgrade steps
    if (from < 2) await m.addColumn(todos, todos.isSynced);
    if (from < 3) await m.createTable(categories);
    if (from < 4) {
      // Data migration: set default value for new column
      await customStatement('UPDATE todos SET priority = 0 WHERE priority IS NULL');
    }
  },
  beforeOpen: (details) async {
    // Enable WAL mode for better concurrent read performance
    await customStatement('PRAGMA journal_mode=WAL');
  },
);
```

---

## Anti-pattern detection

- Storing tokens in SharedPreferences → Critical security violation
- Direct Drift table access from repositories (use DAOs)
- No schema versioning / migrations planned from day one
- Hive boxes opened multiple times (use singleton)
- Isar opened without error handling on schema mismatch
- Raw SQL strings instead of Drift typed queries (injection risk)
- Large binary blobs in SQLite (use file system + path reference)
- Schema evolution not planned (adding columns without migration)

---

## Uncertainty protocol

- `High` (≥ 0.80): data model clear, query patterns known
- `Medium` (0.60–0.79): data volume or query complexity unclear
- `Low` (< 0.60): no data model defined yet

---

## Cross-skill handoff payload

Use the standard payload from `../../AGENTS.md`.
Set `requesting_skill` to `flutter-storage`.

---

## Output contract

Follow global section order from `../../AGENTS.md`. Also include:

- `Storage solution justification`
- `Schema design (Drift tables or Isar collections)`
- `DAO/service layer design`
- `Migration strategy`
- `Security controls for sensitive data`

---

## Related resources

- `references/drift-guide.md`
- `references/isar-guide.md`
- `references/secure-storage-patterns.md`
- `templates/drift-database.dart`
- `templates/drift-dao.dart`
- `templates/secure-storage-service.dart`
