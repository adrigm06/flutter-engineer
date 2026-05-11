// Repository with networking template — wraps remote + local data sources
// Replace [FeatureName] with actual domain name

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '[feature_name]_repository.g.dart';

// ===========================================================================
// PROVIDERS
// ===========================================================================

@riverpod
FeatureNameRemoteDataSource featureNameRemoteDataSource(Ref ref) =>
    FeatureNameRemoteDataSource(ref.watch(dioProvider));

@riverpod
FeatureNameRepository featureNameRepository(Ref ref) =>
    FeatureNameRepositoryImpl(
      remote: ref.watch(featureNameRemoteDataSourceProvider),
      local: ref.watch(featureNameLocalDataSourceProvider),
    );

// ===========================================================================
// REMOTE DATA SOURCE
// ===========================================================================

class FeatureNameRemoteDataSource {
  const FeatureNameRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<FeatureNameDto>> fetchAll({CancelToken? cancelToken}) async {
    final response = await _dio.get<List<dynamic>>(
      '/feature-names',
      cancelToken: cancelToken,
    );
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(FeatureNameDto.fromJson)
        .toList();
  }

  Future<FeatureNameDto> fetchById(
    String id, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/feature-names/$id',
      cancelToken: cancelToken,
    );
    return FeatureNameDto.fromJson(response.data!);
  }

  Future<FeatureNameDto> create(
    CreateFeatureNameDto body, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/feature-names',
      data: body.toJson(),
      cancelToken: cancelToken,
    );
    return FeatureNameDto.fromJson(response.data!);
  }

  Future<FeatureNameDto> update(
    String id,
    UpdateFeatureNameDto body, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/feature-names/$id',
      data: body.toJson(),
      cancelToken: cancelToken,
    );
    return FeatureNameDto.fromJson(response.data!);
  }

  Future<void> delete(String id, {CancelToken? cancelToken}) async {
    await _dio.delete('/feature-names/$id', cancelToken: cancelToken);
  }
}

// ===========================================================================
// REPOSITORY IMPLEMENTATION
// ===========================================================================

class FeatureNameRepositoryImpl implements FeatureNameRepository {
  const FeatureNameRepositoryImpl({
    required FeatureNameRemoteDataSource remote,
    required FeatureNameLocalDataSource local,
  }) : _remote = remote,
       _local = local;

  final FeatureNameRemoteDataSource _remote;
  final FeatureNameLocalDataSource _local;

  @override
  Stream<List<FeatureNameModel>> watchAll() {
    // Reactive local data — updated by sync
    return _local
        .watchAll()
        .map((dtos) => dtos.map((dto) => dto.toDomain()).toList());
  }

  @override
  Future<List<FeatureNameModel>> getAll() async {
    try {
      // Remote-first: fetch fresh data
      final dtos = await _remote.fetchAll();
      // Update local cache
      await _local.replaceAll(dtos);
      return dtos.map((dto) => dto.toDomain()).toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        // Offline: fall back to cached data
        final cached = await _local.getAll();
        if (cached.isNotEmpty) return cached.map((d) => d.toDomain()).toList();
      }
      throw mapDioException(e);
    }
  }

  @override
  Future<FeatureNameModel> getById(String id) async {
    try {
      final dto = await _remote.fetchById(id);
      await _local.upsert(dto);
      return dto.toDomain();
    } on DioException catch (e) {
      // Try cache on connection error
      if (e.type == DioExceptionType.connectionError) {
        final cached = await _local.getById(id);
        if (cached != null) return cached.toDomain();
      }
      throw mapDioException(e);
    }
  }

  @override
  Future<void> create(CreateFeatureNameRequest request) async {
    try {
      final dto = await _remote.create(
        CreateFeatureNameDto.fromRequest(request),
      );
      await _local.upsert(dto);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _remote.delete(id);
      await _local.deleteById(id);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
