import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Approval history item entity
class ApprovalHistoryItem extends Equatable {
  final String id;
  final String driverId;
  final String adminId;
  final String? adminName;
  final String? previousStatus;
  final String newStatus;
  final String? reason;
  final String? notes;
  final List<String>? documentsReviewed;
  final DateTime createdAt;

  const ApprovalHistoryItem({
    required this.id,
    required this.driverId,
    required this.adminId,
    this.adminName,
    this.previousStatus,
    required this.newStatus,
    this.reason,
    this.notes,
    this.documentsReviewed,
    required this.createdAt,
  });

  /// Get human-readable action description
  String get actionDescription {
    switch (newStatus.toLowerCase()) {
      case 'approved':
        return 'Driver approved';
      case 'rejected':
        return 'Driver rejected';
      case 'pending':
        return 'Status reset to pending';
      case 'under_review':
        return 'Marked for review';
      case 'documents_requested':
        return 'Additional documents requested';
      case 'suspended':
        return 'Driver suspended';
      default:
        return 'Status changed to ${_formatStatus(newStatus)}';
    }
  }

  /// Get status change description
  String get statusChangeDescription {
    if (previousStatus == null) {
      return 'Set to ${_formatStatus(newStatus)}';
    }
    return '${_formatStatus(previousStatus!)} → ${_formatStatus(newStatus)}';
  }

  /// Format status for display
  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Get color for the action
  Color get actionColor {
    switch (newStatus.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'documents_requested':
        return Colors.purple;
      case 'under_review':
        return Colors.blue;
      case 'suspended':
        return Colors.brown;
      default:
        return Colors.orange;
    }
  }

  /// Get icon for the action
  IconData get actionIcon {
    switch (newStatus.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'documents_requested':
        return Icons.upload_file;
      case 'under_review':
        return Icons.visibility;
      case 'suspended':
        return Icons.block;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.history;
    }
  }

  /// Admin display name
  String get adminDisplayName => adminName ?? 'Admin';

  ApprovalHistoryItem copyWith({
    String? id,
    String? driverId,
    String? adminId,
    String? adminName,
    String? previousStatus,
    String? newStatus,
    String? reason,
    String? notes,
    List<String>? documentsReviewed,
    DateTime? createdAt,
  }) {
    return ApprovalHistoryItem(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      previousStatus: previousStatus ?? this.previousStatus,
      newStatus: newStatus ?? this.newStatus,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      documentsReviewed: documentsReviewed ?? this.documentsReviewed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        driverId,
        adminId,
        adminName,
        previousStatus,
        newStatus,
        reason,
        notes,
        documentsReviewed,
        createdAt,
      ];
}
