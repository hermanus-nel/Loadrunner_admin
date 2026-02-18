# CLAUDE.md — LoadRunner Admin

## Project Overview

Flutter admin dashboard for the LoadRunner logistics platform. Manages drivers, shippers, payments, disputes, messaging, analytics, and audit logs.

- **Dart SDK**: `>=3.6.0 <4.0.0`
- **Flutter**: 3.x (stable channel)
- **Backend**: Supabase (auth, database, storage)
- **State Management**: Riverpod with code generation (`@riverpod` annotations)
- **Navigation**: GoRouter (declarative, in `lib/core/navigation/app_router.dart`)
- **Code Generation**: Freezed, json_serializable, riverpod_generator via build_runner

## Common Commands

```bash
flutter pub get                                           # Install dependencies
flutter analyze                                           # Run linter (strict-casts, strict-raw-types enabled)
dart run build_runner build --delete-conflicting-outputs   # Run code generation (Freezed, JSON, Riverpod)
dart run build_runner watch --delete-conflicting-outputs   # Watch mode for code generation
flutter test                                              # Run tests
flutter build apk                                         # Build Android APK
flutter build web                                         # Build for web
```

## Architecture

Clean Architecture with feature-based modules:

```
lib/
├── core/                    # Shared infrastructure
│   ├── components/          # Reusable UI widgets (buttons, dialogs, status badges)
│   ├── error/               # Error handling (AppException, ErrorBoundary, ErrorHandler)
│   ├── navigation/          # GoRouter config (app_router.dart)
│   ├── router/              # Router analytics
│   ├── services/            # Core services (Supabase, BulkSMS, connectivity, session, storage, logger)
│   ├── theme/               # App colors, text styles, dimensions, theme
│   └── utils/               # AppConfig, constants, extensions, formatters, validators
├── features/                # Feature modules
│   ├── auth/                # Authentication (login, signup)
│   ├── dashboard/           # Main dashboard
│   ├── users/               # Driver & user management
│   ├── shippers/            # Shipper management
│   ├── payments/            # Payments & transactions
│   ├── messages/            # Messaging & notifications
│   ├── disputes/            # Dispute resolution
│   ├── analytics/           # Analytics & reporting
│   ├── audit_logs/          # Audit trail
│   ├── sms_usage/           # SMS usage tracking
│   └── more/                # Settings & additional features
└── main.dart                # Entry point with initialization sequence
```

### Feature Module Structure

Each feature follows this layout:

```
feature_name/
├── data/
│   ├── models/              # DTOs with @JsonSerializable
│   └── repositories/        # Repository implementations (Supabase queries)
├── domain/
│   ├── entities/            # Business entities with @freezed
│   └── repositories/        # Abstract repository interfaces
└── presentation/
    ├── controllers/         # Business logic controllers (optional)
    ├── providers/           # Riverpod providers (@riverpod annotated)
    ├── screens/             # Full-page screen widgets
    ├── widgets/             # Feature-specific reusable widgets
    └── routes/              # Feature-specific GoRouter routes (optional)
```

## Code Conventions

- **Linting**: `package:flutter_lints/flutter.yaml` with 70+ additional rules. Strict casts and strict raw types enabled.
- **Quotes**: Prefer single quotes (`prefer_single_quotes`).
- **Trailing commas**: Required (`require_trailing_commas`).
- **Return types**: Always declare (`always_declare_return_types`).
- **Public API types**: Must be annotated (`type_annotate_public_apis`).
- **Named parameters**: Required params come first (`always_put_required_named_parameters_first`).
- **Riverpod**: Use `@riverpod` annotations — generated providers go in `*.g.dart` files.
- **Freezed**: Use `@freezed` for immutable domain entities — generated code in `*.freezed.dart` files.
- **JSON**: Use `@JsonSerializable()` on data models — generated code in `*.g.dart` files.

## Environment Setup

Copy `.env.example` to `.env` and fill in the values:

```
SUPABASE_URL=<your-supabase-project-url>
SUPABASE_ANONKEY=<your-supabase-anon-key>
SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>
BULKSMS_USERNAME=<your-bulksms-username>
BULKSMS_PASSWORD=<your-bulksms-password>
APP_ENV=development
DEBUG_MODE=true
```

Environment is loaded via `flutter_dotenv` in `AppConfig.initialize()` (called from `main.dart`).

## Important Notes

- **Do not commit** `.env` or `.env.production` — they are git-ignored.
- **Generated files** (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`) are excluded from analysis. Re-run `dart run build_runner build --delete-conflicting-outputs` after changing models, entities, or provider definitions.
- **Database schema** reference is available in `schema.txt` at the project root.
- The app uses `MaterialApp.router` with theme switching (light/dark) and a global `ErrorBoundary` wrapper.
- Firebase is configured for push notifications (`firebase_core`, `firebase_messaging`).
