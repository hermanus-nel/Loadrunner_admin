// lib/features/messages/domain/entities/message_template_entity.dart

import 'package:flutter/foundation.dart';

/// Template categories for organization
enum TemplateCategory {
  general,
  documentRequest,
  verification,
  payment,
  warning,
  support;

  static TemplateCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'general':
        return TemplateCategory.general;
      case 'document_request':
      case 'documentrequest':
        return TemplateCategory.documentRequest;
      case 'verification':
        return TemplateCategory.verification;
      case 'payment':
        return TemplateCategory.payment;
      case 'warning':
        return TemplateCategory.warning;
      case 'support':
        return TemplateCategory.support;
      default:
        return TemplateCategory.general;
    }
  }

  String get displayName {
    switch (this) {
      case TemplateCategory.general:
        return 'General';
      case TemplateCategory.documentRequest:
        return 'Document Request';
      case TemplateCategory.verification:
        return 'Verification';
      case TemplateCategory.payment:
        return 'Payment';
      case TemplateCategory.warning:
        return 'Warning';
      case TemplateCategory.support:
        return 'Support';
    }
  }

  String toJson() {
    switch (this) {
      case TemplateCategory.general:
        return 'general';
      case TemplateCategory.documentRequest:
        return 'document_request';
      case TemplateCategory.verification:
        return 'verification';
      case TemplateCategory.payment:
        return 'payment';
      case TemplateCategory.warning:
        return 'warning';
      case TemplateCategory.support:
        return 'support';
    }
  }
}

/// Message Template Entity
@immutable
class MessageTemplateEntity {
  final String id;
  final String name;
  final String? subject;
  final String body;
  final TemplateCategory category;
  final bool isActive;
  final int usageCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  const MessageTemplateEntity({
    required this.id,
    required this.name,
    this.subject,
    required this.body,
    this.category = TemplateCategory.general,
    this.isActive = true,
    this.usageCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  /// Get preview of template body
  String get previewText {
    const maxLength = 80;
    if (body.length <= maxLength) return body;
    return '${body.substring(0, maxLength)}...';
  }

  /// Check if template has placeholders
  bool get hasPlaceholders => body.contains('{{') && body.contains('}}');

  /// Get list of placeholders in template
  List<String> get placeholders {
    final regex = RegExp(r'\{\{(\w+)\}\}');
    return regex.allMatches(body).map((m) => m.group(1)!).toSet().toList();
  }

  /// Fill template with values
  String fillTemplate(Map<String, String> values) {
    var result = body;
    for (final entry in values.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }

  /// Copy with method for immutability
  MessageTemplateEntity copyWith({
    String? id,
    String? name,
    String? subject,
    String? body,
    TemplateCategory? category,
    bool? isActive,
    int? usageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return MessageTemplateEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageTemplateEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Default templates that can be seeded
class DefaultTemplates {
  static const List<Map<String, dynamic>> templates = [
    {
      'name': 'Document Re-submission',
      'subject': 'Document Re-submission Required',
      'body': 'Dear {{user_name}},\n\nWe require you to re-submit your {{document_type}} as the previous submission could not be verified.\n\nPlease upload a clear, legible copy at your earliest convenience.\n\nThank you,\nLoadRunner Team',
      'category': 'document_request',
    },
    {
      'name': 'Verification Approved',
      'subject': 'Account Verified Successfully',
      'body': 'Dear {{user_name}},\n\nCongratulations! Your driver account has been verified successfully. You can now start accepting shipment requests.\n\nWelcome to LoadRunner!\n\nBest regards,\nLoadRunner Team',
      'category': 'verification',
    },
    {
      'name': 'Verification Rejected',
      'subject': 'Verification Not Approved',
      'body': 'Dear {{user_name}},\n\nUnfortunately, we were unable to approve your driver verification at this time.\n\nReason: {{rejection_reason}}\n\nPlease address the issues mentioned and re-submit your documents.\n\nRegards,\nLoadRunner Team',
      'category': 'verification',
    },
    {
      'name': 'Payment Issue',
      'subject': 'Payment Issue Notification',
      'body': 'Dear {{user_name}},\n\nWe noticed an issue with your recent payment for shipment #{{shipment_id}}.\n\nPlease contact our support team if you need assistance resolving this matter.\n\nThank you,\nLoadRunner Team',
      'category': 'payment',
    },
    {
      'name': 'Account Warning',
      'subject': 'Account Warning Notice',
      'body': 'Dear {{user_name}},\n\nThis is a warning regarding {{warning_reason}}.\n\nPlease ensure compliance with our terms of service to avoid any interruption to your account.\n\nRegards,\nLoadRunner Team',
      'category': 'warning',
    },
    {
      'name': 'General Support',
      'subject': 'Support Response',
      'body': 'Dear {{user_name}},\n\nThank you for reaching out to LoadRunner support.\n\n{{response_content}}\n\nIf you have any further questions, please don\'t hesitate to contact us.\n\nBest regards,\nLoadRunner Support Team',
      'category': 'support',
    },
  ];
}
