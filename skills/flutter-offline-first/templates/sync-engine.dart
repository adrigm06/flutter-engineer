// Offline-first sync engine — queue-based, idempotent, with conflict resolution
// Replace [FeatureName] and sync logic with your domain entities

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_engine.g.dart';

// ===========================================================================
// SYNC ENGINE INTERFACE
// ===========================================================================

abstract interface class SyncEngine {
  /// Enqueue a local change for background sync
  Future<void> enqueue(SyncTask task);

  /// Process all pending queued tasks
  Future<SyncResult> processQueue();

  /// Full sync: fetch all remote data and replace local
  Future<SyncResult> fullSync();

  /// Current connectivity-aware sync status
  Stream<SyncStatus> get status;
}

// ===========================================================================
// SYNC TASK MODEL
// ===========================================================================

enum SyncTaskType { create, update, delete }

class SyncTask {
  const SyncTask({
    required this.id,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.payload,  // JSON-serialized entity
    this.retryCount = 0,
    this.nextRetryAt,
  });

  final String id;
  final SyncTaskType type;
  final String entityType;  // e.g., 'product', 'order'
  final String entityId;
  final Map<String, dynamic> payload;
  final int retryCount;
  final DateTime? nextRetryAt;

  bool get isEligibleForSync =>
      nextRetryAt == null || nextRetryAt!.isBefore(DateTime.now());
}

// ===========================================================================
// SYNC RESULT
// ===========================================================================

class SyncResult {
  const SyncResult({
    required this.succeeded,
    required this.failed,
    required this.conflicts,
  });

  final int succeeded;
  final int failed;
  final List<SyncConflict> conflicts;

  bool get hasConflicts => conflicts.isNotEmpty;
  bool get allSucceeded => failed == 0;
}

// ===========================================================================
// CONFLICT MODEL
// ===========================================================================

class SyncConflict {
  const SyncConflict({
    required this.entityType,
    required this.entityId,
    required this.localVersion,
    required this.remoteVersion,
    required this.resolution,
  });

  final String entityType;
  final String entityId;
  final Map<String, dynamic> localVersion;
  final Map<String, dynamic> remoteVersion;
  final ConflictResolution resolution;
}

enum ConflictResolution {
  /// Remote wins — server is source of truth (default)
  remoteWins,
  /// Local wins — offline edits override server (user explicitly resolved)
  localWins,
  /// Merge — field-level merge (requires domain-specific logic)
  merged,
}

// ===========================================================================
// SYNC ENGINE IMPLEMENTATION
// ===========================================================================

@riverpod
SyncEngine syncEngine(Ref ref) => SyncEngineImpl(
  queueDao: ref.watch(syncQueueDaoProvider),
  networkClient: ref.watch(dioProvider),
  connectivity: ref.watch(connectivityServiceProvider),
);

class SyncEngineImpl implements SyncEngine {
  SyncEngineImpl({
    required this.queueDao,
    required this.networkClient,
    required this.connectivity,
  });

  final SyncQueueDao queueDao;
  final Dio networkClient;
  final ConnectivityService connectivity;

  @override
  Future<void> enqueue(SyncTask task) async {
    // Idempotent: use entityType+entityId as deduplication key
    await queueDao.upsert(SyncQueueCompanion(
      taskId: Value(task.id),
      taskType: Value(task.type.name),
      entityType: Value(task.entityType),
      entityId: Value(task.entityId),
      payload: Value(jsonEncode(task.payload)),
    ));
  }

  @override
  Future<SyncResult> processQueue() async {
    if (!await connectivity.isConnected()) {
      return const SyncResult(succeeded: 0, failed: 0, conflicts: []);
    }

    final pending = await queueDao.getPending(limit: 50);
    int succeeded = 0;
    int failed = 0;
    final conflicts = <SyncConflict>[];

    for (final task in pending) {
      try {
        final conflict = await _processTask(task);
        if (conflict != null) conflicts.add(conflict);
        await queueDao.remove(task.id);
        succeeded++;
      } on ConflictException catch (conflict) {
        final resolved = _resolveConflict(conflict);
        conflicts.add(resolved);
        if (resolved.resolution == ConflictResolution.localWins) {
          // Retry with forced local version
          await _forceWrite(task, resolved.localVersion);
          await queueDao.remove(task.id);
          succeeded++;
        } else {
          // Remote wins — discard local, pull remote version
          await queueDao.remove(task.id);
          succeeded++;
        }
      } on NetworkException {
        // Exponential backoff: 1s → 2s → 4s → ... → max 1h
        final backoff = Duration(
          seconds: min(3600, pow(2, task.retryCount).toInt()),
        );
        await queueDao.incrementRetry(task.id,
          nextRetryAt: DateTime.now().add(backoff),
        );
        failed++;
      }
    }

    return SyncResult(succeeded: succeeded, failed: failed, conflicts: conflicts);
  }

  Future<SyncConflict?> _processTask(SyncQueueEntry task) async {
    switch (SyncTaskType.values.byName(task.taskType)) {
      case SyncTaskType.create:
        await networkClient.post('/api/${task.entityType}', data: task.payload);
      case SyncTaskType.update:
        await networkClient.patch(
          '/api/${task.entityType}/${task.entityId}',
          data: task.payload,
        );
      case SyncTaskType.delete:
        await networkClient.delete('/api/${task.entityType}/${task.entityId}');
    }
    return null;
  }

  ConflictResolution _defaultResolutionPolicy(String entityType) {
    // Override per entity type as needed
    return switch (entityType) {
      'user_profile' => ConflictResolution.localWins, // User intent wins
      _ => ConflictResolution.remoteWins,             // Server is source of truth
    };
  }

  SyncConflict _resolveConflict(ConflictException e) => SyncConflict(
    entityType: e.entityType,
    entityId: e.entityId,
    localVersion: e.localVersion,
    remoteVersion: e.remoteVersion,
    resolution: _defaultResolutionPolicy(e.entityType),
  );

  @override
  Stream<SyncStatus> get status => connectivity.onConnectivityChanged.map(
    (connected) => connected ? SyncStatus.online : SyncStatus.offline,
  );
}

// ===========================================================================
// BACKGROUND SYNC TRIGGER
// ===========================================================================

// Triggered by WorkManager (Android) / BGTaskScheduler (iOS)
@pragma('vm:entry-point')
void backgroundSyncCallback() {
  Workmanager().executeTask((task, inputData) async {
    await Firebase.initializeApp();
    final container = ProviderContainer();
    try {
      final result = await container.read(syncEngineProvider).processQueue();
      return result.allSucceeded ? true : Future.value(false);
    } finally {
      container.dispose();
    }
  });
}
