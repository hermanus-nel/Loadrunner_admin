# LoadRunner Admin Dashboard

Administrative mobile application for managing the LoadRunner logistics platform.

## Overview

The LoadRunner Admin Dashboard is a separate Flutter application that enables company administrators to efficiently manage the LoadRunner logistics platform. It shares the same Supabase backend as the main LoadRunner app.

### Key Features (Planned)

- **User Management**: Approve/reject driver registrations, manage shippers
- **Document Verification**: Review and verify driver documents and vehicles
- **Payment Management**: View transactions, process refunds, track revenue
- **Dispute Resolution**: Handle disputes between shippers and drivers
- **Communication**: Send messages and push notifications to users
- **Analytics**: View platform statistics and performance metrics
- **Bank Verification**: Verify driver bank accounts via Paystack API
- **Audit Logging**: Track all administrative actions

## Architecture

This project follows **Clean Architecture** with feature-based organization:

```
lib/
├── core/                    # Shared utilities and services
│   ├── components/          # Reusable UI components
│   ├── error/               # Error handling
│   ├── navigation/          # GoRouter configuration
│   ├── services/            # Core services (API, storage)
│   ├── theme/               # App theme and styling
│   └── utils/               # Utility functions
│
├── features/                # Feature modules
│   ├── auth/                # Authentication
│   ├── dashboard/           # Home dashboard
│   ├── users/               # Driver/Shipper management
│   ├── payments/            # Transaction management
│   ├── messages/            # Communication
│   └── more/                # Settings and additional features
│
└── main.dart                # App entry point
```

Each feature follows the Clean Architecture pattern:
- `data/` - Models, repositories implementation
- `domain/` - Entities, repository interfaces
- `presentation/` - Screens, widgets, controllers, providers

## Getting Started

### Prerequisites

- Flutter 3.6.1 or higher
- Dart SDK 3.6.0 or higher
- Access to LoadRunner Supabase project
- Android Studio / VS Code with Flutter extensions
- Xcode (for iOS development)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd loadrunner_admin
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` and add your Supabase credentials:
   ```
   SUPABASE_URL=https://your-project-ref.supabase.co
   SUPABASE_ANON_KEY=your-supabase-anon-key
   ```

4. **Run the app**
   ```bash
   # Debug mode
   flutter run

   # Release mode
   flutter run --release
   ```

### Building for Production

**Android:**
```bash
# APK
flutter build apk --release

# App Bundle (recommended for Play Store)
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## Configuration

### Supabase Setup

This app shares the Supabase backend with the main LoadRunner app. Ensure the following tables exist in your database:

- `users` (with `role` field supporting 'Admin', 'Driver', 'Shipper')
- `driver_docs`
- `vehicles`
- `driver_bank_accounts`
- `freight_posts`
- `admin_audit_logs` (created by admin dashboard migration)
- `driver_approval_history` (created by admin dashboard migration)
- `disputes` (created by admin dashboard migration)
- `admin_messages` (created by admin dashboard migration)

Run the migration file in `supabase/migrations/` to add admin-specific tables.

### Firebase Setup (Push Notifications)

1. Create a Firebase project
2. Add Android and iOS apps in Firebase Console
3. Download and add configuration files:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

## Development

### Code Generation

This project uses code generation for:
- Riverpod providers (`riverpod_generator`)
- JSON serialization (`json_serializable`)
- Freezed for immutable models (`freezed`)

After modifying files that use these annotations, run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Or watch for changes:
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Project Structure Guidelines

- **State Management**: Use Riverpod for all state management
- **Navigation**: Use GoRouter for navigation
- **API Calls**: Use repositories to abstract data sources
- **Error Handling**: Use custom exceptions and Result pattern
- **Styling**: Use AppColors, AppTextStyles, AppDimensions from theme

### Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test
```

## Related Documentation

- [Database Schema Documentation](docs/DATABASE_SCHEMA.md)
- [Database Schema Migration](supabase/migrations/20260127_admin_dashboard_schema_v2.sql)

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `SUPABASE_URL` | Yes | Supabase project URL |
| `SUPABASE_ANON_KEY` | Yes | Supabase anonymous key |
| `APP_ENV` | No | Environment (development/staging/production) |
| `DEBUG_MODE` | No | Enable debug logging (default: true) |
| `API_TIMEOUT` | No | API timeout in seconds (default: 30) |
| `STORAGE_BUCKET` | No | Storage bucket name (default: admin-uploads) |
| `MAX_UPLOAD_SIZE_MB` | No | Max upload size in MB (default: 10) |

## Tech Stack

- **Framework**: Flutter 3.6+
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **Charts**: fl_chart
- **HTTP Client**: Dio
- **Local Storage**: flutter_secure_storage, shared_preferences
- **Push Notifications**: Firebase Cloud Messaging

## Version History

- **1.0.0** - Initial release (in development)

## License

This project is proprietary software owned by LoadRunner. All rights reserved.

## Support

For technical support or questions, contact the LoadRunner development team.
