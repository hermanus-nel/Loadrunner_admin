// lib/features/shippers/data/repositories/shippers_repository_impl.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/jwt_recovery_handler.dart';
import '../../../../core/services/session_service.dart';
import '../../domain/entities/shipper_entity.dart';
import '../../domain/repositories/shippers_repository.dart';

class ShippersRepositoryImpl implements ShippersRepository {
  final SupabaseClient _supabase;
  final JwtRecoveryHandler _jwtHandler;
  final SessionService _sessionService;

  ShippersRepositoryImpl({
    required SupabaseClient supabase,
    required JwtRecoveryHandler jwtHandler,
    required SessionService sessionService,
  })  : _supabase = supabase,
        _jwtHandler = jwtHandler,
        _sessionService = sessionService;

  String? get _adminId => _sessionService.userId;

  @override
  Future<ShippersResult> fetchShippers({
    ShipperFilters? filters,
    ShippersPagination? pagination,
  }) async {
    return _jwtHandler.executeWithRecovery(() async {
      try {
        final page = pagination?.page ?? 1;
        final pageSize = pagination?.pageSize ?? 20;
        final offset = (page - 1) * pageSize;

        // Build query for shippers (role = 'Shipper')
        var query = _supabase
            .from('users')
            .select('id, phone_number, first_name, last_name, email, '
                'profile_photo_url, created_at, updated_at, last_login_at, '
                'is_suspended, suspended_at, suspended_reason, suspended_by, '
                'suspension_ends_at, address_name')
            .eq('role', 'Shipper');

        // Apply status filter
        if (filters?.status != null) {
          switch (filters!.status!) {
            case ShipperStatus.active:
              query = query.eq('is_suspended', false);
              break;
            case ShipperStatus.suspended:
              query = query.eq('is_suspended', true);
              break;
            case ShipperStatus.inactive:
              final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
              query = query
                  .eq('is_suspended', false)
                  .lt('last_login_at', thirtyDaysAgo.toIso8601String());
              break;
          }
        }

        // Apply date filters
        if (filters?.registeredAfter != null) {
          query = query.gte('created_at', filters!.registeredAfter!.toIso8601String());
        }
        if (filters?.registeredBefore != null) {
          query = query.lte('created_at', filters!.registeredBefore!.toIso8601String());
        }
        if (filters?.lastActiveAfter != null) {
          query = query.gte('last_login_at', filters!.lastActiveAfter!.toIso8601String());
        }

        // Apply search filter
        if (filters?.searchQuery != null && filters!.searchQuery!.isNotEmpty) {
          final searchTerm = filters.searchQuery!.toLowerCase();
          query = query.or(
            'first_name.ilike.%$searchTerm%,'
            'last_name.ilike.%$searchTerm%,'
            'email.ilike.%$searchTerm%,'
            'phone_number.ilike.%$searchTerm%',
          );
        }

        // Get total count
        final countQuery = _supabase
            .from('users')
            .select('id')
            .eq('role', 'Shipper');
        final countResult = await countQuery;
        final totalCount = countResult.length;

        // Apply sorting and pagination
        final sortColumn = filters?.sortBy.columnName ?? 'created_at';
        final ascending = filters?.sortAscending ?? false;

        final result = await query
            .order(sortColumn, ascending: ascending)
            .range(offset, offset + pageSize - 1);

        // Map to entities and fetch stats for each
        final shippers = await Future.wait(
          (result as List).map((json) async {
            final shipper = ShipperEntity.fromJson(json as Map<String, dynamic>);
            final stats = await _fetchShipperStats(shipper.id);
            return shipper.copyWith(stats: stats);
          }),
        );

        return (
          shippers: shippers,
          pagination: ShippersPagination(
            page: page,
            pageSize: pageSize,
            totalCount: totalCount,
            hasMore: offset + shippers.length < totalCount,
          ),
          error: null,
        );
      } catch (e) {
        return (
          shippers: <ShipperEntity>[],
          pagination: const ShippersPagination(),
          error: 'Failed to fetch shippers: ${e.toString()}',
        );
      }
    });
  }

  @override
  Future<ShipperDetailResult> fetchShipperDetail(String shipperId) async {
    return _jwtHandler.executeWithRecovery(() async {
      try {
        // Fetch shipper
        final result = await _supabase
            .from('users')
            .select('id, phone_number, first_name, last_name, email, '
                'profile_photo_url, created_at, updated_at, last_login_at, '
                'is_suspended, suspended_at, suspended_reason, suspended_by, '
                'suspension_ends_at, address_name')
            .eq('id', shipperId)
            .eq('role', 'Shipper')
            .single();

        final shipper = ShipperEntity.fromJson(result);

        // Fetch stats
        final stats = await _fetchShipperStats(shipperId);

        // Fetch recent shipments
        final shipmentsResult = await _supabase
            .from('freight_posts')
            .select('id, pickup_location_name, dropoff_location_name, status, created_at')
            .eq('shipper_id', shipperId)
            .order('created_at', ascending: false)
            .limit(10);

        final recentShipments = (shipmentsResult as List)
            .map((json) => ShipperRecentShipment.fromJson(json as Map<String, dynamic>))
            .toList();

        // Fetch payment amounts for shipments
        final shipmentIds = recentShipments.map((s) => s.id).toList();
        if (shipmentIds.isNotEmpty) {
          final paymentsResult = await _supabase
              .from('payments')
              .select('freight_post_id, amount')
              .inFilter('freight_post_id', shipmentIds)
              .eq('status', 'completed');

          final paymentMap = <String, double>{};
          for (final payment in paymentsResult as List) {
            final postId = payment['freight_post_id'] as String;
            final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
            paymentMap[postId] = amount;
          }

          // Update shipments with amounts
          final updatedShipments = recentShipments.map((s) {
            return ShipperRecentShipment(
              id: s.id,
              pickupLocation: s.pickupLocation,
              deliveryLocation: s.deliveryLocation,
              status: s.status,
              amount: paymentMap[s.id],
              createdAt: s.createdAt,
            );
          }).toList();

          return (
            shipper: shipper.copyWith(stats: stats),
            recentShipments: updatedShipments,
            error: null,
          );
        }

        return (
          shipper: shipper.copyWith(stats: stats),
          recentShipments: recentShipments,
          error: null,
        );
      } catch (e) {
        return (
          shipper: null,
          recentShipments: <ShipperRecentShipment>[],
          error: 'Failed to fetch shipper details: ${e.toString()}',
        );
      }
    });
  }

  @override
  Future<ShipperActionResult> suspendShipper(
    String shipperId, {
    required String reason,
    DateTime? endsAt,
  }) async {
    return _jwtHandler.executeWithRecovery(() async {
      try {
        // Get current admin ID
        final adminId = _adminId;

        await _supabase.from('users').update({
          'is_suspended': true,
          'suspended_at': DateTime.now().toIso8601String(),
          'suspended_reason': reason,
          'suspended_by': adminId,
          'suspension_ends_at': endsAt?.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', shipperId);

        // Log the action
        await _logAdminAction(
          action: 'shipper_suspended',
          targetType: 'user',
          targetId: shipperId,
          details: {
            'reason': reason,
            'ends_at': endsAt?.toIso8601String(),
          },
        );

        return (success: true, error: null);
      } catch (e) {
        return (success: false, error: 'Failed to suspend shipper: ${e.toString()}');
      }
    });
  }

  @override
  Future<ShipperActionResult> unsuspendShipper(String shipperId) async {
    return _jwtHandler.executeWithRecovery(() async {
      try {
        await _supabase.from('users').update({
          'is_suspended': false,
          'suspended_at': null,
          'suspended_reason': null,
          'suspended_by': null,
          'suspension_ends_at': null,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', shipperId);

        // Log the action
        await _logAdminAction(
          action: 'shipper_unsuspended',
          targetType: 'user',
          targetId: shipperId,
        );

        return (success: true, error: null);
      } catch (e) {
        return (success: false, error: 'Failed to unsuspend shipper: ${e.toString()}');
      }
    });
  }

  @override
  Future<ShipperActionResult> updateShipperProfile(
    String shipperId, {
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    return _jwtHandler.executeWithRecovery(() async {
      try {
        final updates = <String, dynamic>{
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (firstName != null) updates['first_name'] = firstName;
        if (lastName != null) updates['last_name'] = lastName;
        if (email != null) updates['email'] = email;

        await _supabase.from('users').update(updates).eq('id', shipperId);

        // Log the action
        await _logAdminAction(
          action: 'shipper_profile_updated',
          targetType: 'user',
          targetId: shipperId,
          details: updates,
        );

        return (success: true, error: null);
      } catch (e) {
        return (success: false, error: 'Failed to update profile: ${e.toString()}');
      }
    });
  }

  @override
  Future<ShippersStatsResult> getOverviewStats() async {
    return _jwtHandler.executeWithRecovery(() async {
      try {
        // Total shippers
        final totalResult = await _supabase
            .from('users')
            .select('id')
            .eq('role', 'Shipper');
        final totalShippers = (totalResult as List).length;

        // Suspended shippers
        final suspendedResult = await _supabase
            .from('users')
            .select('id')
            .eq('role', 'Shipper')
            .eq('is_suspended', true);
        final suspendedShippers = (suspendedResult as List).length;

        // New this month
        final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
        final newMonthResult = await _supabase
            .from('users')
            .select('id')
            .eq('role', 'Shipper')
            .gte('created_at', startOfMonth.toIso8601String());
        final newThisMonth = (newMonthResult as List).length;

        // New this week
        final startOfWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
        final newWeekResult = await _supabase
            .from('users')
            .select('id')
            .eq('role', 'Shipper')
            .gte('created_at', startOfWeek.toIso8601String());
        final newThisWeek = (newWeekResult as List).length;

        // Active shippers (logged in within last 30 days)
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        final activeResult = await _supabase
            .from('users')
            .select('id')
            .eq('role', 'Shipper')
            .eq('is_suspended', false)
            .gte('last_login_at', thirtyDaysAgo.toIso8601String());
        final activeShippers = (activeResult as List).length;

        // Total revenue from completed payments
        final revenueResult = await _supabase
            .from('payments')
            .select('amount')
            .eq('status', 'completed');
        double totalRevenue = 0.0;
        for (final payment in revenueResult as List) {
          totalRevenue += (payment['amount'] as num?)?.toDouble() ?? 0.0;
        }

        return (
          stats: ShippersOverviewStats(
            totalShippers: totalShippers,
            activeShippers: activeShippers,
            suspendedShippers: suspendedShippers,
            newThisMonth: newThisMonth,
            newThisWeek: newThisWeek,
            totalRevenue: totalRevenue,
          ),
          error: null,
        );
      } catch (e) {
        return (stats: null, error: 'Failed to fetch stats: ${e.toString()}');
      }
    });
  }

  @override
  Future<ShippersResult> searchShippers(String query) async {
    return fetchShippers(
      filters: ShipperFilters(searchQuery: query),
      pagination: const ShippersPagination(pageSize: 50),
    );
  }

  @override
  Future<ShippersResult> getRecentlyActiveShippers({int limit = 10}) async {
    return _jwtHandler.executeWithRecovery(() async {
      try {
        final result = await _supabase
            .from('users')
            .select('id, phone_number, first_name, last_name, email, '
                'profile_photo_url, created_at, updated_at, last_login_at, '
                'is_suspended, suspended_at, suspended_reason, suspended_by, '
                'suspension_ends_at, address_name')
            .eq('role', 'Shipper')
            .eq('is_suspended', false)
            .not('last_login_at', 'is', null)
            .order('last_login_at', ascending: false)
            .limit(limit);

        final shippers = (result as List)
            .map((json) => ShipperEntity.fromJson(json as Map<String, dynamic>))
            .toList();

        return (
          shippers: shippers,
          pagination: ShippersPagination(
            page: 1,
            pageSize: limit,
            totalCount: shippers.length,
            hasMore: false,
          ),
          error: null,
        );
      } catch (e) {
        return (
          shippers: <ShipperEntity>[],
          pagination: const ShippersPagination(),
          error: 'Failed to fetch active shippers: ${e.toString()}',
        );
      }
    });
  }

  @override
  Future<ShippersResult> getNewShippers({int days = 7, int limit = 10}) async {
    return _jwtHandler.executeWithRecovery(() async {
      try {
        final daysAgo = DateTime.now().subtract(Duration(days: days));

        final result = await _supabase
            .from('users')
            .select('id, phone_number, first_name, last_name, email, '
                'profile_photo_url, created_at, updated_at, last_login_at, '
                'is_suspended, suspended_at, suspended_reason, suspended_by, '
                'suspension_ends_at, address_name')
            .eq('role', 'Shipper')
            .gte('created_at', daysAgo.toIso8601String())
            .order('created_at', ascending: false)
            .limit(limit);

        final shippers = (result as List)
            .map((json) => ShipperEntity.fromJson(json as Map<String, dynamic>))
            .toList();

        return (
          shippers: shippers,
          pagination: ShippersPagination(
            page: 1,
            pageSize: limit,
            totalCount: shippers.length,
            hasMore: false,
          ),
          error: null,
        );
      } catch (e) {
        return (
          shippers: <ShipperEntity>[],
          pagination: const ShippersPagination(),
          error: 'Failed to fetch new shippers: ${e.toString()}',
        );
      }
    });
  }

  @override
  Future<ShippersResult> getSuspendedShippers() async {
    return fetchShippers(
      filters: const ShipperFilters(status: ShipperStatus.suspended),
    );
  }

  // Private helper methods

  Future<ShipperStats> _fetchShipperStats(String shipperId) async {
    try {
      // Total shipments
      final shipmentsResult = await _supabase
          .from('freight_posts')
          .select('id, status')
          .eq('shipper_id', shipperId);

      final shipments = shipmentsResult as List;
      final totalShipments = shipments.length;
      final activeShipments = shipments
          .where((s) => ['Posted', 'Bidding', 'Accepted', 'In Transit'].contains(s['status']))
          .length;
      final completedShipments = shipments.where((s) => s['status'] == 'Delivered').length;
      final cancelledShipments = shipments.where((s) => s['status'] == 'Cancelled').length;

      // Total spent
      final paymentsResult = await _supabase
          .from('payments')
          .select('amount')
          .eq('shipper_id', shipperId)
          .eq('status', 'completed');
      double totalSpent = 0.0;
      for (final payment in paymentsResult as List) {
        totalSpent += (payment['amount'] as num?)?.toDouble() ?? 0.0;
      }

      // Average rating
      final ratingsResult = await _supabase
          .from('ratings')
          .select('rating')
          .eq('rated_user_id', shipperId);
      final ratings = ratingsResult as List;
      double averageRating = 0.0;
      if (ratings.isNotEmpty) {
        final sum = ratings.fold<double>(0.0, (sum, r) => sum + (r['rating'] as num).toDouble());
        averageRating = sum / ratings.length;
      }

      // Disputes
      final disputesResult = await _supabase
          .from('disputes')
          .select('id, status')
          .or('raised_by.eq.$shipperId,raised_against.eq.$shipperId');
      final disputes = disputesResult as List;
      final disputesCount = disputes.length;
      final openDisputesCount = disputes
          .where((d) => ['open', 'investigating', 'awaiting_evidence'].contains(d['status']))
          .length;

      return ShipperStats(
        totalShipments: totalShipments,
        activeShipments: activeShipments,
        completedShipments: completedShipments,
        cancelledShipments: cancelledShipments,
        totalSpent: totalSpent,
        averageRating: averageRating,
        ratingsCount: ratings.length,
        disputesCount: disputesCount,
        openDisputesCount: openDisputesCount,
      );
    } catch (e) {
      return const ShipperStats();
    }
  }

  Future<void> _logAdminAction({
    required String action,
    required String targetType,
    String? targetId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final adminId = _adminId;
      if (adminId == null) return;

      await _supabase.from('admin_audit_logs').insert({
        'admin_id': adminId,
        'action': action,
        'target_type': targetType,
        'target_id': targetId,
        'new_values': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Silently fail audit logging
    }
  }
}
