// lib/features/sms_usage/data/repositories/sms_usage_repository_impl.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/jwt_recovery_handler.dart';
import '../../domain/repositories/sms_usage_repository.dart';

class SmsUsageRepositoryImpl implements SmsUsageRepository {
  final SupabaseClient _supabase;
  final JwtRecoveryHandler _jwtHandler;

  SmsUsageRepositoryImpl({
    required SupabaseClient supabase,
    required JwtRecoveryHandler jwtHandler,
  })  : _supabase = supabase,
        _jwtHandler = jwtHandler;

  @override
  Future<SmsUsageResult> fetchSmsLogs({
    SmsLogFilters? filters,
    SmsLogsPagination? pagination,
  }) async {
    return _jwtHandler.executeWithRecovery(() async {
      try {
        final page = pagination?.page ?? 1;
        final pageSize = pagination?.pageSize ?? 50;
        final offset = (page - 1) * pageSize;

        var query = _supabase.from('sms_billing').select(
            'id, phone_number, message_content, cost_cents, '
            'created_at, sent_at');

        query = _applyFilters(query, filters);

        // Get total count
        final countQuery = _buildCountQuery(filters);
        final countResult = await countQuery;
        final totalCount = countResult.length;

        // Apply sorting and pagination
        final result = await query
            .order('created_at', ascending: false)
            .range(offset, offset + pageSize - 1);

        final logs = (result as List).map((json) {
          final row = json as Map<String, dynamic>;
          return SmsLogEntity.fromJson(_mapBillingToLog(row));
        }).toList();

        return (
          logs: logs,
          pagination: SmsLogsPagination(
            page: page,
            pageSize: pageSize,
            totalCount: totalCount,
            hasMore: offset + logs.length < totalCount,
          ),
          error: null,
        );
      } catch (e) {
        return (
          logs: <SmsLogEntity>[],
          pagination: const SmsLogsPagination(),
          error: 'Failed to fetch SMS logs: ${e.toString()}',
        );
      }
    });
  }

  @override
  Future<SmsStatsResult> getSmsStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _jwtHandler.executeWithRecovery(() async {
      try {
        var query = _supabase
            .from('sms_billing')
            .select('cost_cents, is_paid, created_at');

        if (startDate != null) {
          query = query.gte('created_at', startDate.toIso8601String());
        }
        if (endDate != null) {
          final endOfDay = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
            23,
            59,
            59,
          );
          query = query.lte('created_at', endOfDay.toIso8601String());
        }

        final result = await query;
        final rows = result as List;

        int totalSent = rows.length;
        int totalDelivered = totalSent; // all billing entries are sent
        int totalFailed = 0;
        double totalCost = 0.0;
        final byType = <String, int>{'notification': totalSent};
        final costByType = <String, double>{};

        for (final row in rows) {
          final costCents = (row['cost_cents'] as num?)?.toDouble() ?? 0.0;
          totalCost += costCents / 100.0;
        }

        costByType['notification'] = totalCost;
        final deliveryRate =
            totalSent > 0 ? (totalDelivered / totalSent) * 100 : 0.0;

        return (
          stats: SmsUsageStats(
            totalSent: totalSent,
            totalDelivered: totalDelivered,
            totalFailed: totalFailed,
            totalCost: totalCost,
            deliveryRate: deliveryRate,
            byType: byType,
            costByType: costByType,
          ),
          error: null,
        );
      } catch (e) {
        return (
          stats: null,
          error: 'Failed to fetch SMS stats: ${e.toString()}',
        );
      }
    });
  }

  @override
  Future<DailyUsageResult> getDailyUsage({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _jwtHandler.executeWithRecovery(() async {
      try {
        final effectiveStart =
            startDate ?? DateTime.now().subtract(const Duration(days: 30));
        final effectiveEnd = endDate ?? DateTime.now();

        var query = _supabase
            .from('sms_billing')
            .select('created_at, cost_cents')
            .gte('created_at', effectiveStart.toIso8601String())
            .lte('created_at', DateTime(
              effectiveEnd.year,
              effectiveEnd.month,
              effectiveEnd.day,
              23,
              59,
              59,
            ).toIso8601String())
            .order('created_at', ascending: true);

        final result = await query;
        final rows = result as List;

        // Group by date
        final dailyMap = <String, DailyUsage>{};

        for (final row in rows) {
          final createdAt = DateTime.parse(row['created_at'] as String);
          final dateKey =
              '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
          final cost = ((row['cost_cents'] as num?)?.toDouble() ?? 0.0) / 100.0;

          final existing = dailyMap[dateKey];
          if (existing != null) {
            dailyMap[dateKey] = DailyUsage(
              date: existing.date,
              count: existing.count + 1,
              delivered: existing.delivered + 1,
              failed: existing.failed,
              cost: existing.cost + cost,
            );
          } else {
            dailyMap[dateKey] = DailyUsage(
              date: DateTime(createdAt.year, createdAt.month, createdAt.day),
              count: 1,
              delivered: 1,
              failed: 0,
              cost: cost,
            );
          }
        }

        return (
          dailyUsage: dailyMap.values.toList(),
          error: null,
        );
      } catch (e) {
        return (
          dailyUsage: <DailyUsage>[],
          error: 'Failed to fetch daily usage: ${e.toString()}',
        );
      }
    });
  }

  /// Map sms_billing row to the shape SmsLogEntity.fromJson expects
  Map<String, dynamic> _mapBillingToLog(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'phone_number': row['phone_number'],
      'message_body': row['message_content'],
      'sms_type': 'notification',
      'status': 'delivered',
      'cost': ((row['cost_cents'] as num?)?.toDouble() ?? 0.0) / 100.0,
      'created_at': row['created_at'] ?? row['sent_at'],
    };
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _applyFilters(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> query,
    SmsLogFilters? filters,
  ) {
    if (filters == null) return query;

    if (filters.dateFrom != null) {
      query = query.gte('created_at', filters.dateFrom!.toIso8601String());
    }

    if (filters.dateTo != null) {
      final endOfDay = DateTime(
        filters.dateTo!.year,
        filters.dateTo!.month,
        filters.dateTo!.day,
        23,
        59,
        59,
      );
      query = query.lte('created_at', endOfDay.toIso8601String());
    }

    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
      query = query.ilike('phone_number', '%${filters.searchQuery}%');
    }

    return query;
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _buildCountQuery(
    SmsLogFilters? filters,
  ) {
    var query = _supabase.from('sms_billing').select('id');

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
    if (filters?.searchQuery != null && filters!.searchQuery!.isNotEmpty) {
      query = query.ilike('phone_number', '%${filters.searchQuery}%');
    }

    return query;
  }
}
