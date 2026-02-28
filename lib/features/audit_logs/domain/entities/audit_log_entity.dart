// lib/features/audit_logs/domain/entities/audit_log_entity.dart

import 'package:equatable/equatable.dart';

/// Audit log entry entity
class AuditLogEntity extends Equatable {
  final String id;
  final String adminId;
  final String action;
  final String targetType;
  final String? targetId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;
  
  // Joined admin info
  final AuditLogAdmin? admin;

  const AuditLogEntity({
    required this.id,
    required this.adminId,
    required this.action,
    required this.targetType,
    this.targetId,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
    this.admin,
  });

  /// Get human-readable action description
  String get actionDescription {
    final auditAction = AuditAction.fromString(action);
    if (auditAction != AuditAction.unknown) {
      return auditAction.displayName;
    }
    // Format raw action string: "some_new_action" → "Some New Action"
    return action
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Get action category for grouping/filtering
  AuditActionCategory get actionCategory {
    return AuditAction.fromString(action).category;
  }

  /// Get icon for this action type
  String get actionIcon {
    return AuditAction.fromString(action).icon;
  }

  /// Check if there are changes to show
  bool get hasChanges => oldValues != null || newValues != null;

  /// Get summary of changes
  String? get changesSummary {
    if (newValues == null) return null;
    
    final changes = <String>[];
    newValues!.forEach((key, value) {
      final oldValue = oldValues?[key];
      if (oldValue != value) {
        changes.add('$key: ${_formatValue(oldValue)} → ${_formatValue(value)}');
      }
    });
    
    if (changes.isEmpty && newValues!.isNotEmpty) {
      // Just show new values if no old values to compare
      return newValues!.entries
          .take(3)
          .map((e) => '${e.key}: ${_formatValue(e.value)}')
          .join(', ');
    }
    
    return changes.take(3).join(', ');
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String && value.length > 50) {
      return '${value.substring(0, 50)}...';
    }
    return value.toString();
  }

  /// Get target type display name
  String get targetTypeDisplay {
    return AuditTargetType.fromString(targetType).displayName;
  }

  /// Try to extract a meaningful target name from old/new values
  String? get targetName {
    final values = newValues ?? oldValues;
    if (values == null) return null;

    // Try common name fields
    final firstName = values['first_name'] as String?;
    final lastName = values['last_name'] as String?;
    if (firstName != null || lastName != null) {
      return [firstName, lastName]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');
    }

    final name = values['name'] as String?;
    if (name != null && name.isNotEmpty) return name;

    final companyName = values['company_name'] as String?;
    if (companyName != null && companyName.isNotEmpty) return companyName;

    final email = values['email'] as String?;
    if (email != null && email.isNotEmpty) return email;

    final title = values['title'] as String?;
    if (title != null && title.isNotEmpty) return title;

    return null;
  }

  factory AuditLogEntity.fromJson(Map<String, dynamic> json) {
    return AuditLogEntity(
      id: json['id'] as String,
      adminId: json['admin_id'] as String,
      action: json['action'] as String,
      targetType: json['target_type'] as String,
      targetId: json['target_id'] as String?,
      oldValues: json['old_values'] != null
          ? Map<String, dynamic>.from(json['old_values'] as Map)
          : null,
      newValues: json['new_values'] != null
          ? Map<String, dynamic>.from(json['new_values'] as Map)
          : null,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      admin: json['admin'] != null
          ? AuditLogAdmin.fromJson(json['admin'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_id': adminId,
      'action': action,
      'target_type': targetType,
      'target_id': targetId,
      'old_values': oldValues,
      'new_values': newValues,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': createdAt.toIso8601String(),
      'admin': admin?.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        adminId,
        action,
        targetType,
        targetId,
        oldValues,
        newValues,
        ipAddress,
        userAgent,
        createdAt,
        admin,
      ];
}

/// Admin info for audit log
class AuditLogAdmin extends Equatable {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? profilePhotoUrl;

  const AuditLogAdmin({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.profilePhotoUrl,
  });

  String get fullName {
    final parts = [firstName, lastName].where((s) => s != null && s.isNotEmpty);
    return parts.isNotEmpty ? parts.join(' ') : 'Unknown Admin';
  }

  String get initials {
    if (firstName != null && firstName!.isNotEmpty) {
      if (lastName != null && lastName!.isNotEmpty) {
        return '${firstName![0]}${lastName![0]}'.toUpperCase();
      }
      return firstName![0].toUpperCase();
    }
    return 'A';
  }

  factory AuditLogAdmin.fromJson(Map<String, dynamic> json) {
    return AuditLogAdmin(
      id: json['id'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'profile_photo_url': profilePhotoUrl,
    };
  }

  @override
  List<Object?> get props => [id, firstName, lastName, email, profilePhotoUrl];
}

/// Audit action types
enum AuditAction {
  // Driver actions
  driverApproved('driver_approved', 'Driver Approved', AuditActionCategory.driver, '✓'),
  driverRejected('driver_rejected', 'Driver Rejected', AuditActionCategory.driver, '✗'),
  driverSuspended('driver_suspended', 'Driver Suspended', AuditActionCategory.driver, '⊘'),
  driverUnsuspended('driver_unsuspended', 'Driver Unsuspended', AuditActionCategory.driver, '✓'),
  driverDocumentsRequested('driver_documents_requested', 'Documents Requested', AuditActionCategory.driver, '📄'),
  
  // Shipper actions
  shipperSuspended('shipper_suspended', 'Shipper Suspended', AuditActionCategory.shipper, '⊘'),
  shipperUnsuspended('shipper_unsuspended', 'Shipper Unsuspended', AuditActionCategory.shipper, '✓'),
  shipperProfileUpdated('shipper_profile_updated', 'Profile Updated', AuditActionCategory.shipper, '✎'),
  
  // User actions
  userSuspended('user_suspended', 'User Suspended', AuditActionCategory.user, '⊘'),
  userUnsuspended('user_unsuspended', 'User Unsuspended', AuditActionCategory.user, '✓'),
  userProfileUpdated('user_profile_updated', 'Profile Updated', AuditActionCategory.user, '✎'),
  
  // Payment actions
  paymentRefunded('payment_refunded', 'Payment Refunded', AuditActionCategory.payment, '↩'),
  payoutProcessed('payout_processed', 'Payout Processed', AuditActionCategory.payment, '💰'),
  
  // Dispute actions
  disputeAssigned('dispute_assigned', 'Dispute Assigned', AuditActionCategory.dispute, '👤'),
  disputeResolved('dispute_resolved', 'Dispute Resolved', AuditActionCategory.dispute, '✓'),
  disputeEscalated('dispute_escalated', 'Dispute Escalated', AuditActionCategory.dispute, '⬆'),
  disputeStatusUpdated('dispute_status_updated', 'Status Updated', AuditActionCategory.dispute, '↻'),
  disputePriorityUpdated('dispute_priority_updated', 'Priority Updated', AuditActionCategory.dispute, '!'),
  disputeNoteAdded('dispute_note_added', 'Note Added', AuditActionCategory.dispute, '📝'),
  disputeEvidenceRequested('dispute_evidence_requested', 'Evidence Requested', AuditActionCategory.dispute, '📎'),
  
  // Message actions
  messageSent('message_sent', 'Message Sent', AuditActionCategory.message, '✉'),
  broadcastSent('broadcast_sent', 'Broadcast Sent', AuditActionCategory.message, '📢'),
  
  // Vehicle actions
  vehicleApproved('vehicle_approved', 'Vehicle Approved', AuditActionCategory.vehicle, '✓'),
  vehicleRejected('vehicle_rejected', 'Vehicle Rejected', AuditActionCategory.vehicle, '✗'),
  
  // Auth actions
  adminLogin('admin_login', 'Admin Login', AuditActionCategory.auth, '🔐'),
  adminLogout('admin_logout', 'Admin Logout', AuditActionCategory.auth, '🚪'),
  
  // Generic
  unknown('unknown', 'Unknown Action', AuditActionCategory.other, '•');

  final String value;
  final String displayName;
  final AuditActionCategory category;
  final String icon;

  const AuditAction(this.value, this.displayName, this.category, this.icon);

  static AuditAction fromString(String value) {
    return AuditAction.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AuditAction.unknown,
    );
  }
}

/// Categories for grouping audit actions
enum AuditActionCategory {
  driver('Driver'),
  shipper('Shipper'),
  user('User'),
  payment('Payment'),
  dispute('Dispute'),
  message('Message'),
  vehicle('Vehicle'),
  auth('Authentication'),
  other('Other');

  final String displayName;

  const AuditActionCategory(this.displayName);
}

/// Target types for filtering
enum AuditTargetType {
  user('user', 'User'),
  driver('driver', 'Driver'),
  shipper('shipper', 'Shipper'),
  vehicle('vehicle', 'Vehicle'),
  payment('payment', 'Payment'),
  dispute('dispute', 'Dispute'),
  message('message', 'Message'),
  shipment('shipment', 'Shipment'),
  freightPost('freight_post', 'Shipment'),
  other('other', 'Other');

  final String value;
  final String displayName;

  const AuditTargetType(this.value, this.displayName);

  static AuditTargetType fromString(String value) {
    return AuditTargetType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AuditTargetType.other,
    );
  }
}

/// Filter options for audit logs
class AuditLogFilters extends Equatable {
  final String? adminId;
  final String? action;
  final AuditActionCategory? category;
  final String? targetType;
  final String? targetId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? searchQuery;

  const AuditLogFilters({
    this.adminId,
    this.action,
    this.category,
    this.targetType,
    this.targetId,
    this.dateFrom,
    this.dateTo,
    this.searchQuery,
  });

  bool get hasActiveFilters {
    return adminId != null ||
        action != null ||
        category != null ||
        targetType != null ||
        targetId != null ||
        dateFrom != null ||
        dateTo != null ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }

  AuditLogFilters copyWith({
    String? adminId,
    String? action,
    AuditActionCategory? category,
    String? targetType,
    String? targetId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? searchQuery,
    bool clearAdminId = false,
    bool clearAction = false,
    bool clearCategory = false,
    bool clearTargetType = false,
    bool clearTargetId = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
    bool clearSearchQuery = false,
  }) {
    return AuditLogFilters(
      adminId: clearAdminId ? null : (adminId ?? this.adminId),
      action: clearAction ? null : (action ?? this.action),
      category: clearCategory ? null : (category ?? this.category),
      targetType: clearTargetType ? null : (targetType ?? this.targetType),
      targetId: clearTargetId ? null : (targetId ?? this.targetId),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }

  @override
  List<Object?> get props => [
        adminId,
        action,
        category,
        targetType,
        targetId,
        dateFrom,
        dateTo,
        searchQuery,
      ];
}

/// Pagination info
class AuditLogsPagination extends Equatable {
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;

  const AuditLogsPagination({
    this.page = 1,
    this.pageSize = 50,
    this.totalCount = 0,
    this.hasMore = false,
  });

  int get offset => (page - 1) * pageSize;

  AuditLogsPagination copyWith({
    int? page,
    int? pageSize,
    int? totalCount,
    bool? hasMore,
  }) {
    return AuditLogsPagination(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [page, pageSize, totalCount, hasMore];
}

/// Statistics for audit logs
class AuditLogsStats extends Equatable {
  final int totalLogs;
  final int logsToday;
  final int logsThisWeek;
  final Map<String, int> actionCounts;
  final Map<String, int> adminCounts;

  const AuditLogsStats({
    this.totalLogs = 0,
    this.logsToday = 0,
    this.logsThisWeek = 0,
    this.actionCounts = const {},
    this.adminCounts = const {},
  });

  factory AuditLogsStats.fromJson(Map<String, dynamic> json) {
    return AuditLogsStats(
      totalLogs: json['total_logs'] as int? ?? 0,
      logsToday: json['logs_today'] as int? ?? 0,
      logsThisWeek: json['logs_this_week'] as int? ?? 0,
      actionCounts: Map<String, int>.from(json['action_counts'] as Map? ?? {}),
      adminCounts: Map<String, int>.from(json['admin_counts'] as Map? ?? {}),
    );
  }

  @override
  List<Object?> get props => [totalLogs, logsToday, logsThisWeek, actionCounts, adminCounts];
}
