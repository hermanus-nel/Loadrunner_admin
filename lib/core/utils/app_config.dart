import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration loaded from environment variables
class AppConfig {
  AppConfig._();

  static final AppConfig _instance = AppConfig._();
  static AppConfig get instance => _instance;

  /// Initialize configuration (call in main.dart before runApp)
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
  }

  // ===========================================
  // SUPABASE
  // ===========================================

  /// Supabase project URL
  String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  /// Supabase anonymous key
  String get supabaseAnonKey => dotenv.env['SUPABASE_ANONKEY'] ?? '';

  /// Check if Supabase is configured
  bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // ===========================================
  // APP SETTINGS
  // ===========================================

  /// Current environment (development, staging, production)
  String get environment => dotenv.env['APP_ENV'] ?? 'development';

  /// Whether debug mode is enabled
  bool get isDebugMode => dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';

  /// Whether this is production environment
  bool get isProduction => environment == 'production';

  /// Whether this is development environment
  bool get isDevelopment => environment == 'development';

  /// API timeout in seconds
  int get apiTimeout => int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30') ?? 30;

  // ===========================================
  // STORAGE
  // ===========================================

  /// Storage bucket name for admin uploads
  String get storageBucket => dotenv.env['STORAGE_BUCKET'] ?? 'admin-uploads';

  /// Maximum upload size in MB
  int get maxUploadSizeMb =>
      int.tryParse(dotenv.env['MAX_UPLOAD_SIZE_MB'] ?? '10') ?? 10;

  /// Maximum upload size in bytes
  int get maxUploadSizeBytes => maxUploadSizeMb * 1024 * 1024;

  // ===========================================
  // OPTIONAL INTEGRATIONS
  // ===========================================

  /// Paystack public key (for bank verification)
  String? get paystackPublicKey => dotenv.env['PAYSTACK_PUBLIC_KEY'];

  /// Whether Paystack is configured
  bool get isPaystackConfigured =>
      paystackPublicKey != null && paystackPublicKey!.isNotEmpty;

  /// BulkSMS username
  String get bulkSmsUsername => dotenv.env['BULKSMS_USERNAME'] ?? '';

  /// BulkSMS password
  String get bulkSmsPassword => dotenv.env['BULKSMS_PASSWORD'] ?? '';

  /// Whether BulkSMS is configured
  bool get isBulkSmsConfigured =>
      bulkSmsUsername.isNotEmpty && bulkSmsPassword.isNotEmpty;
}
