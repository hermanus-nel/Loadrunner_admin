// lib/features/audit_logs/data/repositories/audit_logs_repository_impl.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/jwt_recovery_handler.dart';
import '../../domain/entities/audit_log_entity.dart';
import '../../domain/repositories/audit_logs_repository.dart';

class AuditLogsRepositoryImpl implements AuditLogsRepository {
  final SupabaseClient _supabase;
  final JwtRecoveryHandler _jwtHandler;

  AuditLogsRepositoryImpl({
    required SupabaseClient supabase,
    required JwtRecoveryHandler jwtHandler,
  })  : _supabase = supabase,
        _jwtHandler = jwtHandler;

  @override
  Future<AuditLogsResult> fetchAuditLogs({
    AuditLogFilters? filters,
    AuditLogsPagination? pagination,
  }) async {
    return _jwtHandler.executeWithRecovery(() async {
      try {
        final page = pagination?.page ?? 1;
        final pageSize = pagination?.pageSize ?? 50;
        final offset = (page - 1) * pageSize;

        // Build base query with admin join
        var query = _supabase
            .from('admin_audit_logs')
            .select('''
              *,
              admin:admin_id (
                id,
                first_name,
                last_name,
                email,
                profile_photo_url
              )
            ''');

        // Apply filters
        if (filters?.adminId != null) {
          query = query.eq('admin_id', filters!.adminId!);
        }

        if (filters?.action != null) {
          query = query.eq('action', filters!.action!);
        }

        if (filters?.category != null) {
          // Filter by action category (actions that belong to this category)
          final actionsInCategory = AuditAction.values
              .where((a) => a.category == filters!.category)
              .map((a) => a.value)
              .toList();
          if (actionsInCategory.isNotEmpty) {
            query = query.inFilter('action', actionsInCategory);
          }
        }

        if (filters?.targetType != null) {
          query = query.eq('target_type', filters!.targetType!);
        }

        if (filters?.targetId != null) {
          query = query.eq('target_id', filters!.targetId!);
        }

        if (filters?.dateFrom != null) {
          query = query.gte('created_at', filters!.dateFrom!.toIso8601String());
        }

        if (filters?.dateTo != null) {
          // Add one day to include the entire day
          final endOfDay = DateTime(
            filters!.dateTo!.year,
            filters.dateTo!.month,
            filters.dateTo!.day,
            23,
            59,
            59,
          );
          query = query.lte('created_at', endOfDay.toIso8601String());
        }

        // Get total count for pagination
        final countQuery = _buildCountQuery(filters);
        final countResult = await countQuery;
        final totalCount = countResult.length;

        // Apply sorting (newest first) and pagination
        final result = await query
            .order('created_at', ascending: false)
            .range(offset, offset + pageSize - 1);

        final logs = (result as List).map((json) {
          return AuditLogEntity.fromJson(json as Map<String, dynamic>);
        }).toList();

        return (
          logs: logs,
          pagination: AuditLogsPagination(
            page: page,
            pageSize: pageSize,
            totalCount: totalCount,
            hasMore: offset + logs.length < totalCount,
          ),
          error: null,
        );
      } catch (e) {
        return (
          logs: <AuditLogEntity>[],
          pagination: const AuditLogsPagination(),
          error: 'Failed to fetch audit logs: ${e.toString()}',
        );
      }
    });
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _buildCountQuery(
      AuditLogFilters? filters) {
    var query = _supabase.from('admin_audit_logs').select('id');

    if (filters?.adminId != null) {
      query = query.eq('admin_id', filters!.adminId!);
    }
    if (filters?.action != null) {
      query = query.eq('action', filters!.action!);
    }
    if (filters?.category != null) {
      final actionsInCategory = AuditAction.values
          .where((a) => a.category == filters!.category)
          .map((a) => a.value)
          .toList();
      if (actionsInCategory.isNotEmpty) {
        query = query.inFilter('action', actionsInCategory);
      }
    }
    if (filters?.targetType != null) {
      query = query.eq('target_type', filters!.targetType!);
    }
    if (filters?.targetId != null) {
      query = query.eq('target_id', filters!.targetId!);
    }
    if (filters?.dateFrom != null) {
      query = query.gte('created_at', filters!.dateFrom!.toIso8601String());
    }
    if (filters?.dateTo != null) {
      final endOfDay = DateTime(
        filters!.dateTo!.year,
        filters.dateTo!.month,
        filters.dateTo!.day,
        23,
        59,
        59,
      );
      query = query.lte('created_at', endOfDay.toIso8601String());
    }

    return query;
  }

  @override
  Future<AuditLogEntity?> fetchAuditLogById(String logId) async {
    return _jwtHandler.executeWithRecovery(() async {
      try {
        final result = await _supabase
            .from('admin_audit_logs')
            .select('''
              *,
              admin:admin_id (
                id,
                first_name,
                last_name,
                email,
                profile_photo_url
              )
            ''')
            .eq('id', logId)
            .single();

        return AuditLogEntity.fromJson(result);
      } catch (e) {
        return null;
      }
    });
  }

  @override
  Future<AuditLogsResult> fetchLogsForTarget({
    required String targetType,
    required String targetId,
    AuditLogsPagination? pagination,
  }) async {
    return fetchAuditLogs(
      filters: AuditLogFilters(
        targetType: targetType,
        targetId: targetId,
      ),
      pagination: pagination,
    );
  }

  @override
  Future<AuditLogsResult> fetchLogsByAdmin({
    required String adminId,
    AuditLogFilters? filters,
    AuditLogsPagination? pagination,
  }) async {
    return fetchAuditLogs(
      filters: (filters ?? const AuditLogFilters()).copyWith(adminId: adminId),
      pagination: pagination,
    );
  }

  @override
  Future<AuditLogsStatsResult> getStats({
    DateTime? from,
    DateTime? to,
  }) async {
    return _jwtHandler.executeWithRecovery(() async {
      try {
        // Total logs
        final totalQuery = _supabase.from('admin_audit_logs').select('id');
        final totalResult = await totalQuery;
        final totalLogs = totalResult.length;

        // Logs today
        final startOfToday = DateTime.now().copyWith(
          hour: 0,
          minute: 0,
          second: 0,
          millisecond: 0,
        );
        final todayResult = await _supabase
            .from('admin_audit_logs')
            .select('id')
            .gte('created_at', startOfToday.toIso8601String());
        final logsToday = todayResult.length;

        // Logs this week
        final startOfWeek = DateTime.now().subtract(
          Duration(days: DateTime.now().weekday - 1),
        ).copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
        final weekResult = await _supabase
            .from('admin_audit_logs')
            .select('id')
            .gte('created_at', startOfWeek.toIso8601String());
        final logsThisWeek = weekResult.length;

        // Action counts (top 10)
        final actionsResult = await _supabase
            .from('admin_audit_logs')
            .select('action');
        final actionCounts = <String, int>{};
        for (final log in actionsResult as List) {
          final action = log['action'] as String;
          actionCounts[action] = (actionCounts[action] ?? 0) + 1;
        }

        // Admin counts (top 10)
        final adminsResult = await _supabase
            .from('admin_audit_logs')
            .select('admin_id');
        final adminCounts = <String, int>{};
        for (final log in adminsResult as List) {
          final adminId = log['admin_id'] as String;
          adminCounts[adminId] = (adminCounts[adminId] ?? 0) + 1;
        }

        return (
          stats: AuditLogsStats(
            totalLogs: totalLogs,
            logsToday: logsToday,
            logsThisWeek: logsThisWeek,
            actionCounts: actionCounts,
            adminCounts: adminCounts,
          ),
          error: null,
        );
      } catch (e) {
        return (stats: null, error: 'Failed to fetch stats: ${e.toString()}');
      }
    });
  }

  @override
  Future<AdminsListResult> getActiveAdmins() async {
    return _jwtHandler.executeWithRecovery(() async {
      try {
        // Get unique admin IDs from audit logs
        final logsResult = await _supabase
            .from('admin_audit_logs')
            .select('admin_id')
            .order('created_at', ascending: false)
            .limit(1000);

        final uniqueAdminIds = <String>{};
        for (final log in logsResult as List) {
          uniqueAdminIds.add(log['admin_id'] as String);
        }

        if (uniqueAdminIds.isEmpty) {
          return (admins: <AuditLogAdmin>[], error: null);
        }

        // Fetch admin details
        final adminsResult = await _supabase
            .from('users')
            .select('id, first_name, last_name, email, profile_photo_url')
            .inFilter('id', uniqueAdminIds.toList());

        final admins = (adminsResult as List)
            .map((json) => AuditLogAdmin.fromJson(json as Map<String, dynamic>))
            .toList();

        return (admins: admins, error: null);
      } catch (e) {
        return (
          admins: <AuditLogAdmin>[],
          error: 'Failed to fetch admins: ${e.toString()}',
        );
      }
    });
  }

  @override
  Future<List<String>> getDistinctActions() async {
    return _jwtHandler.executeWithRecovery(() async {
      try {
        final result = await _supabase
            .from('admin_audit_logs')
            .select('action')
            .order('action');

        final actions = <String>{};
        for (final log in result as List) {
          actions.add(log['action'] as String);
        }

        return actions.toList()..sort();
      } catch (e) {
        return [];
      }
    });
  }

  @override
  Future<String?> exportLogs({
    AuditLogFilters? filters,
    DateTime? from,
    DateTime? to,
  }) async {
    return _jwtHandler.executeWithRecovery(() async {
      try {
        final exportFilters = (filters ?? const AuditLogFilters()).copyWith(
          dateFrom: from,
          dateTo: to,
        );

        // Fetch all logs matching filters (limit to 10000)
        final result = await fetchAuditLogs(
          filters: exportFilters,
          pagination: const AuditLogsPagination(page: 1, pageSize: 10000),
        );

        if (result.error != null) return null;

        // Build CSV
        final buffer = StringBuffer();
        buffer.writeln('ID,Admin,Action,Target Type,Target ID,IP Address,Created At');

        for (final log in result.logs) {
          buffer.writeln([
            log.id,
            log.admin?.fullName ?? log.adminId,
            log.action,
            log.targetType,
            log.targetId ?? '',
            log.ipAddress ?? '',
            log.createdAt.toIso8601String(),
          ].map((s) => '"${s.toString().replaceAll('"', '""')}"').join(','));
        }

        return buffer.toString();
      } catch (e) {
        return null;
      }
    });
  }
}
