# Feature-First Folder Structure

## Canonical layout (single-package app)

```
lib/
  features/
    auth/
      presentation/
        screens/
          login_screen.dart
          register_screen.dart
        widgets/
          login_form.dart
          social_login_buttons.dart
        view_models/
          login_view_model.dart     # Riverpod Notifier
      application/                  # Use cases (only if needed)
        sign_in_use_case.dart
      domain/
        models/
          user.dart
          auth_failure.dart
        repositories/
          auth_repository.dart      # Abstract interface
        exceptions/
          auth_exception.dart
      data/
        repositories/
          auth_repository_impl.dart # Concrete implementation
        data_sources/
          remote/
            auth_remote_data_source.dart
          local/
            auth_local_data_source.dart
        dtos/
          user_dto.dart
          login_request_dto.dart
    home/
      presentation/
      domain/
      data/
    profile/
      presentation/
      domain/
      data/
  core/
    network/
      api_client.dart
      interceptors/
        auth_interceptor.dart
        retry_interceptor.dart
        logging_interceptor.dart
    storage/
      app_database.dart
      daos/
      secure_token_storage.dart
    routing/
      app_router.dart
      routes.dart
    di/
      providers.dart              # Riverpod providers wiring
    utils/
      result.dart                 # Result<T, E> type
      validators.dart
    extensions/
      string_extensions.dart
      datetime_extensions.dart
    theme/
      app_theme.dart
      app_colors.dart
      app_spacing.dart
      app_typography.dart
    l10n/
      app_en.arb
      app_es.arb
  bootstrap/
    bootstrap.dart               # App initialization
    error_handler.dart
  main.dart
  main_dev.dart
  main_staging.dart
```

## Package-first layout (Melos monorepo)

```
my_workspace/
  apps/
    consumer_app/
      lib/
        main.dart
        app.dart                 # MaterialApp.router setup
        core/
          di/
            app_providers.dart   # Wire all feature packages
          routing/
            app_router.dart      # Route tree from all features
  packages/
    core/
      core_network/
      core_storage/
      core_auth/
    design_system/
    features/
      feature_auth/
        lib/
          src/
            presentation/
            application/
            domain/
            data/
          feature_auth.dart      # Barrel export (public API only)
      feature_home/
      feature_checkout/
```

## Rules

1. **No global `screens/`, `widgets/`, `models/`, `services/` directories** — ever.
2. Each feature is a self-contained vertical slice.
3. `core/` contains only cross-cutting infrastructure (not business logic).
4. `domain/` contains pure Dart — no Flutter imports, no platform imports.
5. `data/` implements `domain/repositories/` interfaces.
6. `presentation/` imports `domain/` models and repositories only (not `data/`).
7. One barrel export per feature package (`feature_name.dart`) — export public API only.

## What goes in `core/` vs `features/`

| Code | Location |
|---|---|
| Dio client, interceptors | `core/network/` |
| Drift database, DAOs | `core/storage/` |
| go_router configuration | `core/routing/` |
| Riverpod DI wiring | `core/di/` |
| Design tokens, theme | `core/theme/` |
| l10n ARB files | `core/l10n/` |
| Auth token storage | `core/storage/` (or `core/auth/`) |
| Auth UI, login screen | `features/auth/` |
| Auth domain model | `features/auth/domain/` |
| Home feed logic | `features/home/` |
| Shared reusable widgets | `design_system/` (own package) |
