# Dependency Rules

## The Dependency Rule

> Source code dependencies must point inward (toward domain/business rules).
> Nothing in an inner layer can know about outer layers.

```
presentation ──depends on──► domain
data         ──depends on──► domain
domain       ──depends on──► (nothing — pure Dart only)

presentation does NOT depend on data
data does NOT depend on presentation
```

## Allowed dependencies (per layer)

| Layer | May import | May NOT import |
|---|---|---|
| `domain/` | Dart stdlib, third-party value types (e.g., `freezed`) | `flutter/*`, `data/*`, `presentation/*` |
| `data/` | `domain/` interfaces, `drift`, `dio`, `flutter_secure_storage` | `presentation/*`, Flutter widgets |
| `application/` (use cases) | `domain/` | `data/` directly, `presentation/*` |
| `presentation/` | `domain/` models and repo interfaces, `core/theme`, `core/routing` | `data/` implementations directly |
| `core/` | External packages | `features/*` |

## Package-level rules (monorepo)

```
✅  apps/* → feature_*
✅  apps/* → core_*
✅  apps/* → design_system
✅  feature_* → core_*
✅  feature_* → design_system
✅  core_* → external packages only
✅  design_system → external UI packages only

❌  feature_a → feature_b (direct)
❌  core_* → feature_*
❌  design_system → feature_*
❌  apps/* → apps/* (cross-app imports)
```

## Why feature_a cannot import feature_b

- Creates hidden coupling that prevents independent deployment/testing
- Changes in feature_b can silently break feature_a
- Blocks team autonomy — teams must coordinate changes

**Alternative**: share code through `core_*` package or raise shared model to domain layer.

## Detecting violations

```bash
# In CI using custom Dart script
dart run tools/check_imports.dart

# Example check: no 'features/auth' imported from 'features/home'
# dart analyze catches some violations via package visibility
```

## Dependency inversion at the data boundary

```dart
// ✅ Correct: domain defines the interface
// domain/repositories/auth_repository.dart
abstract interface class AuthRepository {
  Future<Result<User, AuthFailure>> signIn({
    required String email,
    required String password,
  });
}

// ✅ Correct: data implements it
// data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
  });

  @override
  Future<Result<User, AuthFailure>> signIn({...}) async { ... }
}

// ✅ Correct: DI wires implementation to interface (in core/di or app-level)
@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    local: ref.watch(authLocalDataSourceProvider),
  );
}

// ✅ Correct: presentation depends on interface only
class LoginNotifier extends _$LoginNotifier {
  @override
  LoginState build() => const LoginState.initial();

  Future<void> signIn(String email, String password) async {
    final repo = ref.read(authRepositoryProvider); // interface, not impl
    ...
  }
}
```
