/// Core module exports
/// Import this file to access all core utilities, services, and theme
library core;

// Theme
export 'theme/app_colors.dart';
export 'theme/app_dimensions.dart';
export 'theme/app_text_styles.dart';
export 'theme/app_theme.dart';

// Utils
export 'utils/app_config.dart';
export 'utils/constants.dart';
export 'utils/extensions.dart';
export 'utils/formatters.dart';
export 'utils/validators.dart';

// Services
export 'services/session_service.dart';
export 'services/supabase_provider.dart';
export 'services/jwt_recovery_handler.dart';
export 'services/bulksms_service.dart';
export 'services/core_providers.dart';
export 'services/connectivity_service.dart';
export 'services/logger_service.dart';
export 'services/storage_service.dart';

// Navigation
export 'navigation/app_router.dart';

// Components
export 'components/main_scaffold.dart';

// Error handling
export 'error/exceptions.dart';
