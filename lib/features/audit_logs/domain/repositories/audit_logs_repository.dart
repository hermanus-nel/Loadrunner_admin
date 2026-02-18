// lib/features/audit_logs/domain/repositories/audit_logs_repository.dart

import '../entities/audit_log_entity.dart';

/// Result types for repository operations
typedef AuditLogsResult = ({
  List<AuditLogEntity> logs,
  AuditLogsPagination pagination,
  String? error,
});

typedef AuditLogsStatsResult = ({
  AuditLogsStats? stats,
  String? error,
});

typedef AdminsListResult = ({
  List<AuditLogAdmin> admins,
  String? error,
});

/// Repository interface for audit logs
abstract class AuditLogsRepository {
  /// Fetch paginated audit logs with optional filters
  Future<AuditLogsResult> fetchAuditLogs({
    AuditLogFilters? filters,
    AuditLogsPagination? pagination,
  });

  /// Fetch a single audit log entry by ID
  Future<AuditLogEntity?> fetchAuditLogById(String logId);

  /// Fetch logs for a specific target (e.g., all actions on a user)
  Future<AuditLogsResult> fetchLogsForTarget({
    required String targetType,
    required String targetId,
    AuditLogsPagination? pagination,
  });

  /// Fetch logs by a specific admin
  Future<AuditLogsResult> fetchLogsByAdmin({
    required String adminId,
    AuditLogFilters? filters,
    AuditLogsPagination? pagination,
  });

  /// Get statistics for audit logs
  Future<AuditLogsStatsResult> getStats({
    DateTime? from,
    DateTime? to,
  });

  /// Get list of admins who have audit logs (for filter dropdown)
  Future<AdminsListResult> getActiveAdmins();

  /// Get distinct action types from logs (for filter dropdown)
  Future<List<String>> getDistinctActions();

  /// Export audit logs (returns CSV data or similar)
  Future<String?> exportLogs({
    AuditLogFilters? filters,
    DateTime? from,
    DateTime? to,
  });
}
