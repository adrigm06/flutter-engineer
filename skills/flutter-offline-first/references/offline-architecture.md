# Offline-First Architecture Reference

## Local-First Principle

> The app must be fully usable without a network connection.
> The network is an enhancement, not a requirement.

---

## Data flow (offline-first)

```
User action
    │
    ▼
Local write (Drift/Isar) ──► Reactive UI update (immediate)
    │
    ▼
Sync queue (enqueue task)
    │
    ▼
Background sync (when online)
    │
    ▼
Remote write → Remote read → Merge local cache
```

---

## Data freshness strategy

| Strategy | When to use | Implementation |
|---|---|---|
| Cache-first | Data rarely changes (catalog, config) | Read local, refresh in background |
| Remote-first with fallback | Data changes often (feed, notifications) | Try remote, fall back to cache on failure |
| Write-through | User-generated content | Write local + enqueue sync immediately |
| Read-through | Detail views | Check cache, fetch remote, update cache |
| Stale-while-revalidate | Balance freshness and UX | Serve stale immediately, refresh background |

---

## Sync queue design

### Queue entry fields

| Field | Purpose |
|---|---|
| `task_id` | Idempotent deduplication key (UUID) |
| `task_type` | `create`, `update`, `delete` |
| `entity_type` | `product`, `order`, `user_profile` |
| `entity_id` | Remote entity ID |
| `payload` | JSON-serialized entity data |
| `retry_count` | Track for exponential backoff |
| `next_retry_at` | When to next attempt (backoff) |
| `is_processing` | Lock to prevent concurrent processing |
| `created_at` | For ordering and expiry |

### Idempotency rule

Every sync task must be idempotent:
- Use server-generated UUIDs as entity IDs, not auto-increment
- `PUT /entities/{id}` replaces state — safe to retry
- `POST /entities` with idempotency key prevents duplicates
- `DELETE /entities/{id}` with 404 tolerance (already deleted)

```dart
// Set idempotency key on POST requests
await dio.post('/orders',
  data: order.toJson(),
  options: Options(headers: {
    'Idempotency-Key': order.localId, // Stable key for retries
  }),
);
```

---

## Conflict resolution policies

### Default: Remote Wins

Server is source of truth. Local edits lost if conflicting.
Best for: catalog data, admin-managed content, shared state.

### Local Wins

User's offline intent preserved. Server state overwritten.
Best for: user profiles, personal settings, notes.

### Last Write Wins (LWW)

Compare timestamps — latest write wins.
Risk: clock drift between devices.
Best for: simple fields where latest value is correct (e.g., status).

### Field-Level Merge

Merge non-conflicting fields from both versions.
Best for: documents where different users edit different fields.
Implementation: Compare diff against base version (requires storing base version).

```dart
Map<String, dynamic> mergeConflict({
  required Map<String, dynamic> base,     // Version at last sync
  required Map<String, dynamic> local,    // Local offline changes
  required Map<String, dynamic> remote,   // Latest server version
}) {
  final merged = Map.of(remote); // Start with remote
  for (final key in local.keys) {
    // Apply local change only if field unchanged on remote
    if (remote[key] == base[key]) {
      merged[key] = local[key]; // Local wins for this field
    }
    // Otherwise: remote wins (leave merged[key] as remote[key])
  }
  return merged;
}
```

---

## Sync timing strategies

| Trigger | Implementation | When to use |
|---|---|---|
| On reconnection | Listen to connectivity stream → trigger sync | All apps |
| On app foreground | `WidgetsBinding.addObserver` → `didChangeAppLifecycleState` | All apps |
| Background periodic | WorkManager (Android) / BGTaskScheduler (iOS) | Periodic data sync |
| Push notification | FCM → background message → sync trigger | Real-time critical |
| User action | Pull-to-refresh → sync | User-controlled freshness |

---

## Tombstoning (soft deletes)

Never hard-delete locally until sync confirms. Use soft delete:

```dart
// Local delete: mark as deleted, keep record for sync
await localDb.update(products)
  ..where((p) => p.id.equals(id))
  .write(const ProductsCompanion(deletedAt: Value(DateTime.now())));

// Enqueue sync task
await syncEngine.enqueue(SyncTask(
  type: SyncTaskType.delete,
  entityType: 'product',
  entityId: id,
));

// After successful sync: purge tombstoned records
await localDb.delete(products)
  ..where((p) => p.deletedAt.isNotNull()).go();
```

---

## Connectivity monitoring

```dart
@riverpod
Stream<bool> networkConnectivity(Ref ref) {
  return Connectivity().onConnectivityChanged.map(
    (result) => result != ConnectivityResult.none,
  );
}

// Auto-sync on reconnection
@riverpod
void autoSyncOnReconnection(Ref ref) {
  ref.listen(networkConnectivityProvider, (prev, next) async {
    if (next.valueOrNull == true && prev?.valueOrNull == false) {
      // Just reconnected
      await ref.read(syncEngineProvider).processQueue();
    }
  });
}
```
