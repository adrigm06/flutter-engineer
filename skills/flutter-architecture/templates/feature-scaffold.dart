// Feature scaffold — copy and replace [FeatureName] with actual name
// Run after: dart run build_runner build --delete-conflicting-outputs

// ===========================================================================
// DOMAIN LAYER
// ===========================================================================

// lib/features/[feature_name]/domain/models/[feature_name]_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '[feature_name]_model.freezed.dart';

@freezed
class FeatureNameModel with _$FeatureNameModel {
  const factory FeatureNameModel({
    required String id,
    required String title,
    // Add fields here
  }) = _FeatureNameModel;
}

// ===========================================================================

// lib/features/[feature_name]/domain/exceptions/[feature_name]_exception.dart
sealed class FeatureNameException implements Exception {
  const FeatureNameException();
}

class FeatureNameNotFoundException extends FeatureNameException {
  const FeatureNameNotFoundException({required this.id});
  final String id;
}

class FeatureNameNetworkException extends FeatureNameException {
  const FeatureNameNetworkException({this.message});
  final String? message;
}

// ===========================================================================

// lib/features/[feature_name]/domain/repositories/[feature_name]_repository.dart
abstract interface class FeatureNameRepository {
  Stream<List<FeatureNameModel>> watchAll();
  Future<FeatureNameModel> getById(String id);
  Future<void> create(FeatureNameModel model);
  Future<void> update(FeatureNameModel model);
  Future<void> delete(String id);
}

// ===========================================================================
// DATA LAYER
// ===========================================================================

// lib/features/[feature_name]/data/dtos/[feature_name]_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '[feature_name]_dto.freezed.dart';
part '[feature_name]_dto.g.dart';

@freezed
class FeatureNameDto with _$FeatureNameDto {
  const factory FeatureNameDto({
    required String id,
    required String title,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _FeatureNameDto;

  factory FeatureNameDto.fromJson(Map<String, dynamic> json) =>
      _$FeatureNameDtoFromJson(json);

  // Mapper: DTO → Domain
  FeatureNameModel toDomain() => FeatureNameModel(
    id: id,
    title: title,
  );
}

// ===========================================================================

// lib/features/[feature_name]/data/data_sources/remote/[feature_name]_remote_data_source.dart
import 'package:dio/dio.dart';

class FeatureNameRemoteDataSource {
  const FeatureNameRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<FeatureNameDto>> fetchAll() async {
    final response = await _dio.get<List<dynamic>>('/feature-names');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(FeatureNameDto.fromJson)
        .toList();
  }

  Future<FeatureNameDto> fetchById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/feature-names/$id');
    return FeatureNameDto.fromJson(response.data!);
  }

  Future<FeatureNameDto> create(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/feature-names',
      data: body,
    );
    return FeatureNameDto.fromJson(response.data!);
  }
}

// ===========================================================================

// lib/features/[feature_name]/data/repositories/[feature_name]_repository_impl.dart
class FeatureNameRepositoryImpl implements FeatureNameRepository {
  const FeatureNameRepositoryImpl({
    required FeatureNameRemoteDataSource remote,
    required FeatureNameLocalDataSource local,
  }) : _remote = remote, _local = local;

  final FeatureNameRemoteDataSource _remote;
  final FeatureNameLocalDataSource _local;

  @override
  Stream<List<FeatureNameModel>> watchAll() {
    return _local.watchAll().map(
      (dtos) => dtos.map((dto) => dto.toDomain()).toList(),
    );
  }

  @override
  Future<FeatureNameModel> getById(String id) async {
    try {
      final dto = await _remote.fetchById(id);
      await _local.upsert(dto);
      return dto.toDomain();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }
}

// ===========================================================================
// PRESENTATION LAYER — RIVERPOD PROVIDERS
// ===========================================================================

// lib/features/[feature_name]/presentation/providers/[feature_name]_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '[feature_name]_providers.g.dart';

// Remote data source provider
@riverpod
FeatureNameRemoteDataSource featureNameRemoteDataSource(Ref ref) =>
    FeatureNameRemoteDataSource(ref.watch(dioProvider));

// Repository provider
@riverpod
FeatureNameRepository featureNameRepository(Ref ref) =>
    FeatureNameRepositoryImpl(
      remote: ref.watch(featureNameRemoteDataSourceProvider),
      local: ref.watch(featureNameLocalDataSourceProvider),
    );

// List notifier
@riverpod
class FeatureNameList extends _$FeatureNameList {
  @override
  Future<List<FeatureNameModel>> build() {
    return ref.watch(featureNameRepositoryProvider).watchAll().first;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(featureNameRepositoryProvider).watchAll().first,
    );
  }
}

// ===========================================================================
// PRESENTATION LAYER — SCREEN
// ===========================================================================

// lib/features/[feature_name]/presentation/screens/[feature_name]_screen.dart
class FeatureNameScreen extends ConsumerWidget {
  const FeatureNameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(featureNameListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.featureNameTitle)),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (items) => items.isEmpty
            ? const _EmptyState()
            : _FeatureNameList(items: items),
      ),
    );
  }
}

class _FeatureNameList extends StatelessWidget {
  const _FeatureNameList({required this.items});
  final List<FeatureNameModel> items;

  @override
  Widget build(BuildContext context) => ListView.builder(
    key: const ValueKey('feature_name_list'),
    itemCount: items.length,
    itemBuilder: (context, index) => _FeatureNameCard(item: items[index]),
  );
}

class _FeatureNameCard extends StatelessWidget {
  const _FeatureNameCard({required this.item});
  final FeatureNameModel item;

  @override
  Widget build(BuildContext context) => ListTile(
    key: ValueKey('feature_name_card_${item.id}'),
    title: Text(item.title),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      context.l10n.featureNameEmpty,
      key: const ValueKey('feature_name_empty'),
    ),
  );
}
