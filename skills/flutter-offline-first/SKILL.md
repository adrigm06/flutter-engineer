---
name: flutter-offline-first
description: >
  Lead authority for offline-first Flutter architecture. Use when designing local-first
  apps, sync engines, conflict resolution, optimistic UI, retry queues, background sync,
  or mission-critical apps requiring reliability without connectivity.
---

# Flutter Offline-First Skill

## Purpose

Design and implement local-first Flutter architectures that remain fully functional
without network connectivity and synchronize reliably when connectivity is restored.

## Scope and authority

Lead authority for:

- offline-first architectural patterns (local-first, event sourcing, CQRS-lite)
- sync engine design (bidirectional sync, delta sync)
- conflict resolution strategies (LWW, CRDT, manual merge)
- optimistic UI with rollback
- retry queue design and persistence
- background sync (WorkManager, Dart isolates)
- network connectivity awareness

Defers to:

- `flutter-storage` for persistence layer implementation (Drift, Isar)
- `flutter-networking` for remote sync transport (Dio)
- `flutter-state-management` for UI state during sync

---

## When to use

- Designing apps for unreliable connectivity (field workers, developing regions)
- Mission-critical apps requiring offline reliability (medical, logistics, payments)
- Building collaborative features requiring conflict resolution
- Designing sync between local and remote state
- Optimistic updates with network confirmation

---

## Offline-first architecture patterns

### Pattern 1: Repository sync (recommended for most apps)

```
UI → Riverpod Notifier → Repository (single source of truth)
                              ↓               ↑
                       Local DB (Drift)  Remote API (Dio)
                              ↕
                       Background Sync Service
```

The Repository exposes Streams backed by local data. Remote sync updates the local DB,
which reactively updates the Stream, which updates the UI.

```dart
// Offline-first read:
Stream<List<Order>> watchOrders() async* {
  // 1. Immediately yield local data
  yield await _localSource.getOrders();
  // 2. Sync with remote in background
  unawaited(_syncOrders());
  // 3. Watch local DB for changes (reactive)
  yield* _localSource.watchOrders();
}

Future<void> _syncOrders() async {
  try {
    final remoteOrders = await _remoteSource.fetchOrders();
    await _localSource.replaceOrders(remoteOrders);
  } on NetworkException {
    // Silent fail — UI has local data already
    _logger.warning('Sync failed — will retry on next foreground');
  }
}
```

### Pattern 2: Optimistic writes with sync queue

```dart
// Optimistic write: persist locally first, then sync
Future<Result<void>> createOrder(Order order) async {
  // 1. Persist locally immediately (optimistic)
  final localOrder = order.copyWith(
    id: _generateLocalId(),
    syncStatus: SyncStatus.pending,
  );
  await _localSource.insertOrder(localOrder);

  // 2. Attempt immediate remote sync
  try {
    final remoteOrder = await _remoteSource.createOrder(order);
    // 3a. Mark as synced with remote ID
    await _localSource.markSynced(localOrder.id, remoteId: remoteOrder.id);
    return const Result.success(null);
  } on NetworkException {
    // 3b. Queue for background retry
    await _syncQueue.enqueue(SyncTask.createOrder(localOrder.id));
    return const Result.success(null); // Optimistic — show success to user
  }
}
```

### Pattern 3: Background sync queue (Drift-backed)

```dart
// Sync queue persisted in local DB — survives app restart
@DataClassName('SyncTaskEntry')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get taskType => text()();
  TextColumn get payload => text()(); // JSON
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  BoolColumn get isProcessing => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class SyncQueueService {
  final SyncQueueDao _dao;
  final RemoteDataSource _remote;
  Timer? _syncTimer;

  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _syncTimer = Timer.periodic(interval, (_) => processQueue());
  }

  Future<void> processQueue() async {
    final pendingTasks = await _dao.getPendingTasks(limit: 10);

    for (final task in pendingTasks) {
      if (task.retryCount >= 5) {
        await _dao.markFailed(task.id);
        continue;
      }

      try {
        await _executeTask(task);
        await _dao.delete(task.id);
      } catch (e) {
        // Exponential backoff
        final nextRetry = DateTime.now().add(
          Duration(minutes: 1 << task.retryCount),
        );
        await _dao.incrementRetry(task.id, nextRetryAt: nextRetry);
      }
    }
  }

  void dispose() => _syncTimer?.cancel();
}
```

---

## Conflict resolution strategies

### Last-Write-Wins (LWW)
```dart
// Simple: latest timestamp wins
ResolvedRecord resolveConflict(LocalRecord local, RemoteRecord remote) {
  return local.updatedAt.isAfter(remote.updatedAt)
      ? ResolvedRecord.fromLocal(local)
      : ResolvedRecord.fromRemote(remote);
}
```

When to use: non-collaborative data, simple user preferences, last-edit wins acceptably.

### Field-level merge (collaborative editing)
```dart
// Merge non-conflicting field changes
ResolvedOrder mergeOrder(LocalOrder local, RemoteOrder remote, BaseOrder base) {
  return ResolvedOrder(
    // Field changed on local but not remote: keep local
    title: local.title != base.title ? local.title : remote.title,
    // Field changed on remote but not local: keep remote
    status: remote.status != base.status ? remote.status : local.status,
    // Both changed: conflict — flag for user resolution
    assigneeId: (local.assigneeId != base.assigneeId && remote.assigneeId != base.assigneeId)
        ? null // ConflictMarker
        : local.assigneeId != base.assigneeId ? local.assigneeId : remote.assigneeId,
  );
}
```

### CRDT (conflict-free replicated data types)
Use for collaborative documents, shared lists, counters.
Consider `automerge-dart` for complex collaborative scenarios.

---

## Connectivity awareness

```dart
// core/network/connectivity_service.dart
@riverpod
Stream<bool> isOnline(Ref ref) async* {
  final connectivity = Connectivity();
  yield await _checkConnectivity(connectivity);
  yield* connectivity.onConnectivityChanged
      .map((result) => result != ConnectivityResult.none);
}

// Repository using connectivity awareness:
Future<void> sync() async {
  final online = await ref.read(isOnlineProvider.future);
  if (!online) {
    _logger.info('Offline — skipping sync, queuing for later');
    return;
  }
  await processQueue();
}
```

---

## Optimistic UI with rollback

```dart
// Notifier with optimistic update and rollback
@riverpod
class OrderListNotifier extends _$OrderListNotifier {
  @override
  Future<List<Order>> build() async {
    return ref.watch(orderRepositoryProvider).getOrders();
  }

  Future<void> deleteOrder(String orderId) async {
    // Save previous state for rollback
    final previousState = state;

    // Optimistic update: remove from UI immediately
    state = AsyncData(
      state.value!.where((o) => o.id != orderId).toList(),
    );

    try {
      await ref.read(orderRepositoryProvider).deleteOrder(orderId);
    } catch (e) {
      // Rollback on failure
      state = previousState;
      // Show error to user
      ref.read(snackbarProvider.notifier).showError('Failed to delete order');
    }
  }
}
```

---

## Sync status indicators (UI pattern)

```dart
sealed class SyncStatus {
  const SyncStatus();
}
class SyncIdle extends SyncStatus {}
class SyncInProgress extends SyncStatus {}
class SyncSuccess extends SyncStatus {
  final DateTime lastSynced;
  const SyncSuccess(this.lastSynced);
}
class SyncFailed extends SyncStatus {
  final String error;
  final int pendingCount;
  const SyncFailed({required this.error, required this.pendingCount});
}
```

---

## Anti-pattern detection

- Remote data fetched in widget build() (no local cache first)
- No optimistic updates (shows loading spinner for every mutation)
- Sync queue without retry limits (infinite retry loop)
- No conflict resolution strategy documented (leads to silent data loss)
- Background sync without network connectivity check
- Sync queue not persisted (lost on app restart)
- No sync status shown to user (they don't know data is stale)

---

## Cross-skill handoff payload

Use the standard payload from `../../AGENTS.md`.
Set `requesting_skill` to `flutter-offline-first`.

---

## Output contract

Follow global section order from `../../AGENTS.md`. Also include:

- `Offline-first pattern selection and justification`
- `Sync architecture diagram`
- `Conflict resolution strategy`
- `Sync queue design`
- `Optimistic update plan`
- `Connectivity awareness implementation`

---

## Related resources

- `references/offline-first-patterns.md`
- `references/conflict-resolution.md`
- `references/sync-queue-design.md`
- `templates/offline-repository.dart`
- `templates/sync-queue-service.dart`
- `templates/optimistic-notifier.dart`
