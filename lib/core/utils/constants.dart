/// Application-wide constants
class AppConstants {
  AppConstants._();

  // ===========================================
  // APP INFO
  // ===========================================

  static const String appName = 'LoadRunner Admin';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // ===========================================
  // API & NETWORKING
  // ===========================================

  /// Default page size for paginated lists
  static const int defaultPageSize = 20;

  /// Maximum retry attempts for failed requests
  static const int maxRetryAttempts = 3;

  /// Delay between retry attempts (milliseconds)
  static const int retryDelayMs = 1000;

  // ===========================================
  // CACHE
  // ===========================================

  /// Cache duration for user data (minutes)
  static const int userCacheDurationMinutes = 5;

  /// Cache duration for statistics (minutes)
  static const int statsCacheDurationMinutes = 1;

  // ===========================================
  // VALIDATION
  // ===========================================

  /// Minimum password length
  static const int minPasswordLength = 6;

  /// Maximum message length
  static const int maxMessageLength = 1000;

  /// Maximum note length
  static const int maxNoteLength = 500;

  // ===========================================
  // FILE UPLOAD
  // ===========================================

  /// Allowed image extensions
  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];

  /// Allowed document extensions
  static const List<String> allowedDocumentExtensions = [
    'pdf',
    'doc',
    'docx',
  ];

  /// Maximum image dimension (pixels)
  static const int maxImageDimension = 2048;

  /// Image compression quality (0-100)
  static const int imageCompressionQuality = 85;

  // ===========================================
  // UI
  // ===========================================

  /// Debounce duration for search (milliseconds)
  static const int searchDebounceMs = 300;

  /// Animation duration (milliseconds)
  static const int animationDurationMs = 250;

  /// Snackbar duration (seconds)
  static const int snackbarDurationSeconds = 3;

  /// Maximum items to show in quick lists
  static const int quickListMaxItems = 5;

  // ===========================================
  // DATE FORMATS
  // ===========================================

  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd MMM yyyy, HH:mm';
  static const String shortDateFormat = 'dd/MM/yyyy';

  // ===========================================
  // STORAGE KEYS
  // ===========================================

  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';
  static const String lastSyncKey = 'last_sync';
}

/// User role values (matching database enum)
class UserRoles {
  UserRoles._();

  static const String admin = 'Admin';
  static const String driver = 'Driver';
  static const String shipper = 'Shipper';
  static const String guest = 'Guest';
}

/// Verification status values (matching database enum)
class VerificationStatus {
  VerificationStatus._();

  static const String pending = 'pending';
  static const String underReview = 'under_review';
  static const String documentsRequested = 'documents_requested';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String suspended = 'suspended';

  /// Get display label for status
  static String getLabel(String status) {
    switch (status) {
      case pending:
        return 'Pending';
      case underReview:
        return 'Under Review';
      case documentsRequested:
        return 'Documents Requested';
      case approved:
        return 'Approved';
      case rejected:
        return 'Rejected';
      case suspended:
        return 'Suspended';
      default:
        return status;
    }
  }
}

/// Dispute status values (matching database enum)
class DisputeStatus {
  DisputeStatus._();

  static const String open = 'open';
  static const String underReview = 'under_review';
  static const String awaitingResponse = 'awaiting_response';
  static const String resolved = 'resolved';
  static const String closed = 'closed';
  static const String escalated = 'escalated';

  /// Get display label for status
  static String getLabel(String status) {
    switch (status) {
      case open:
        return 'Open';
      case underReview:
        return 'Under Review';
      case awaitingResponse:
        return 'Awaiting Response';
      case resolved:
        return 'Resolved';
      case closed:
        return 'Closed';
      case escalated:
        return 'Escalated';
      default:
        return status;
    }
  }
}

/// Dispute priority values (matching database enum)
class DisputePriority {
  DisputePriority._();

  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String urgent = 'urgent';

  /// Get display label for priority
  static String getLabel(String priority) {
    switch (priority) {
      case low:
        return 'Low';
      case medium:
        return 'Medium';
      case high:
        return 'High';
      case urgent:
        return 'Urgent';
      default:
        return priority;
    }
  }
}

/// Dispute type values (matching database enum)
class DisputeType {
  DisputeType._();

  static const String payment = 'payment';
  static const String delivery = 'delivery';
  static const String damage = 'damage';
  static const String behavior = 'behavior';
  static const String cancellation = 'cancellation';
  static const String other = 'other';

  /// Get display label for type
  static String getLabel(String type) {
    switch (type) {
      case payment:
        return 'Payment Issue';
      case delivery:
        return 'Delivery Issue';
      case damage:
        return 'Cargo Damage';
      case behavior:
        return 'Behavior';
      case cancellation:
        return 'Cancellation';
      case other:
        return 'Other';
      default:
        return type;
    }
  }
}

/// Document types for drivers
class DriverDocTypes {
  DriverDocTypes._();

  static const String idDocument = 'id_document';
  static const String proofOfAddress = 'proof_of_address';
  static const String driversLicense = 'drivers_license';
  static const String pdp = 'pdp'; // Professional Driving Permit

  /// Get display label for document type
  static String getLabel(String docType) {
    switch (docType) {
      case idDocument:
        return 'ID Document';
      case proofOfAddress:
        return 'Proof of Address';
      case driversLicense:
        return "Driver's License";
      case pdp:
        return 'PDP (Professional Driving Permit)';
      default:
        return docType;
    }
  }

  /// All document types
  static const List<String> all = [
    idDocument,
    proofOfAddress,
    driversLicense,
    pdp,
  ];
}

/// Freight status values (matching existing database enum)
class FreightStatus {
  FreightStatus._();

  static const String bidding = 'Bidding';
  static const String pickup = 'Pickup';
  static const String onRoute = 'OnRoute';
  static const String delivered = 'Delivered';
  static const String cancelled = 'Cancelled';

  /// Get display label for status
  static String getLabel(String status) {
    switch (status) {
      case bidding:
        return 'Bidding';
      case pickup:
        return 'Pickup';
      case onRoute:
        return 'On Route';
      case delivered:
        return 'Delivered';
      case cancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }
}

/// Payment status values (matching existing database enum)
class PaymentStatus {
  PaymentStatus._();

  static const String pending = 'pending';
  static const String completed = 'completed';
  static const String failed = 'failed';
  static const String refunded = 'refunded';

  /// Get display label for status
  static String getLabel(String status) {
    switch (status) {
      case pending:
        return 'Pending';
      case completed:
        return 'Completed';
      case failed:
        return 'Failed';
      case refunded:
        return 'Refunded';
      default:
        return status;
    }
  }
}
