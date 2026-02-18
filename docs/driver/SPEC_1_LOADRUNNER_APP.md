# SPEC 1: LoadRunner App — Driver Registration Implementation

**Purpose:** Step-by-step coding spec for implementing automated driver registration in the LoadRunner app.  
**Prerequisite:** Run the database migration (SPEC_DATABASE_MIGRATION.sql) BEFORE coding either app.  
**Architecture:** Flutter clean architecture with Riverpod, Supabase backend.

---

## PART A: Doc Type Normalization (Fix the Root Cause First)

The `doc_type` mismatch between apps is the #1 blocker for auto-verification. Fix this across every file that reads or writes `doc_type`.

### A.1 Create: `lib/features/user/domain/entities/doc_type_map.dart`

```dart
/// Canonical doc_type codes used in the database.
/// Both LoadRunner and Admin apps MUST use these codes in driver_docs.doc_type.
class DocType {
  DocType._();

  // — Canonical codes (stored in DB) —
  static const idDocument = 'id_document';
  static const idBack = 'id_back';
  static const licenseFront = 'license_front';
  static const licenseBack = 'license_back';
  static const pdp = 'pdp';
  static const proofOfAddress = 'proof_of_address';
  static const bankDocument = 'bank_document';
  static const profilePhoto = 'profile_photo';
  static const selfie = 'selfie';

  // — Required docs for registration —
  static const requiredForRegistration = [idDocument, licenseFront];

  // — Required docs for auto-verification —
  static const requiredForAutoVerify = [idDocument, licenseFront];

  /// Map: display label → DB code
  static const Map<String, String> displayToCode = {
    'ID Document': idDocument,
    "Driver's License": licenseFront,
    'Professional Driving Permit (PDP)': pdp,
    'Proof of Address': proofOfAddress,
    'Bank Document': bankDocument,
    'Bank Confirmation Letter': bankDocument,
    'Profile Photo': profilePhoto,
    'Selfie': selfie,
  };

  /// Map: DB code → display label
  static const Map<String, String> codeToDisplay = {
    idDocument: 'ID Document',
    idBack: 'ID Document (Back)',
    licenseFront: "Driver's License",
    licenseBack: "Driver's License (Back)",
    pdp: 'Professional Driving Permit (PDP)',
    proofOfAddress: 'Proof of Address',
    bankDocument: 'Bank Confirmation Letter',
    profilePhoto: 'Profile Photo',
    selfie: 'Selfie',
  };

  /// Convert any doc_type string (legacy or new) to canonical code.
  /// Returns the input unchanged if no mapping exists.
  static String normalize(String docType) {
    // Already a canonical code?
    if (codeToDisplay.containsKey(docType)) return docType;
    // Legacy display label?
    if (displayToCode.containsKey(docType)) return displayToCode[docType]!;
    // Unknown — return as-is (log warning in debug)
    assert(() {
      debugPrint('WARNING: Unknown doc_type "$docType" — not normalized');
      return true;
    }());
    return docType;
  }

  /// Get display label for any doc_type code.
  static String displayLabel(String code) {
    return codeToDisplay[code] ?? code;
  }
}
```

### A.2 Modify: `lib/features/user/domain/entities/document_entity.dart`

Add verification fields that the app currently ignores:

```dart
// ADD these fields to the existing DocumentEntity class:

class DocumentEntity {
  final String? id;
  final String userId;
  final String description;  // This is doc_type — rename internally to docType in future refactor
  final String? docUrl;
  final String? localFilePath;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  // NEW FIELDS — currently in DB but not read by app
  final String verificationStatus;     // 'pending' | 'under_review' | 'approved' | 'rejected' | 'documents_requested'
  final String? rejectionReason;       // From admin review
  final String? adminNotes;            // From admin review
  final String? verifiedBy;            // Admin UUID who verified
  final DateTime? verifiedAt;          // When verified
  final DateTime? expiryDate;          // Document expiry

  const DocumentEntity({
    this.id,
    required this.userId,
    required this.description,
    this.docUrl,
    this.localFilePath,
    this.createdAt,
    this.modifiedAt,
    this.verificationStatus = 'pending',
    this.rejectionReason,
    this.adminNotes,
    this.verifiedBy,
    this.verifiedAt,
    this.expiryDate,
  });

  /// Canonical doc_type code for this document.
  String get docTypeCode => DocType.normalize(description);

  /// Human-readable label.
  String get displayLabel => DocType.displayLabel(docTypeCode);

  /// Whether admin has rejected and driver needs to re-upload.
  bool get needsReupload =>
      verificationStatus == 'rejected' ||
      verificationStatus == 'documents_requested';

  /// Whether admin has approved this document.
  bool get isApproved => verificationStatus == 'approved';

  // Factory from DB row
  factory DocumentEntity.fromMap(Map<String, dynamic> map) {
    return DocumentEntity(
      id: map['id'],
      userId: map['driver_id'] ?? '',
      description: map['doc_type'] ?? '',
      docUrl: map['doc_url'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      modifiedAt: map['modified_at'] != null ? DateTime.parse(map['modified_at']) : null,
      verificationStatus: map['verification_status'] ?? 'pending',
      rejectionReason: map['rejection_reason'],
      adminNotes: map['admin_notes'],
      verifiedBy: map['verified_by'],
      verifiedAt: map['verified_at'] != null ? DateTime.parse(map['verified_at']) : null,
      expiryDate: map['expiry_date'] != null ? DateTime.parse(map['expiry_date']) : null,
    );
  }

  // To DB map — uses normalized code
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'driver_id': userId,
      'doc_type': docTypeCode, // NORMALIZED
      'doc_url': docUrl,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'modified_at': DateTime.now().toIso8601String(),
    };
  }
}
```

### A.3 Modify: `lib/features/user/data/repositories/user_repository_impl.dart`

Every place documents are saved to `driver_docs`, use the normalized code:

```dart
// FIND all occurrences where doc_type is written to driver_docs
// REPLACE the description/doc_type value with DocType.normalize(...)

// BEFORE (example from saveDocuments method):
'doc_type': doc.description,

// AFTER:
'doc_type': DocType.normalize(doc.description),

// ALSO: When reading documents, parse all verification fields:
// BEFORE:
final doc = DocumentEntity(
  id: row['id'],
  userId: row['driver_id'],
  description: row['doc_type'],
  docUrl: row['doc_url'],
  // ... only these fields
);

// AFTER:
final doc = DocumentEntity.fromMap(row);
```

### A.4 Modify: `lib/features/user/presentation/providers/driver_profile_provider.dart`

Update document validation to use normalized codes:

```dart
// BEFORE (matches by human-readable string containing "id"/"driver"):
bool get hasIdDocument => _documents.any((d) =>
    d.description.toLowerCase().contains('id') ||
    d.description.toLowerCase().contains('identity'));

bool get hasDriverLicense => _documents.any((d) =>
    d.description.toLowerCase().contains('driver') ||
    d.description.toLowerCase().contains('license'));

// AFTER (matches by canonical code):
bool get hasIdDocument => _documents.any((d) =>
    d.docTypeCode == DocType.idDocument && d.docUrl != null);

bool get hasDriverLicense => _documents.any((d) =>
    d.docTypeCode == DocType.licenseFront && d.docUrl != null);
```

---

## PART B: Enhanced User Entity — Comprehensive Bid Gating

### B.1 Modify: `lib/features/user/domain/entities/user_entity.dart`

```dart
// ADD this getter (keep isVerified for backward compat but deprecate):

/// DEPRECATED: Use canBid instead. This doesn't check suspension.
bool get isVerified => driverVerifiedAt != null;

/// Comprehensive check: can this driver place bids?
/// Checks: role, verification status, verified timestamp, and suspension.
bool get canBid =>
    role == 'Driver' &&
    driverVerificationStatus == 'approved' &&
    driverVerifiedAt != null &&
    !isSuspended;

/// Whether driver was auto-verified (verified_by is NULL).
/// The DB trigger sets driver_verified_by = NULL for auto-actions,
/// while admin approvals always set it to the admin's real UUID.
bool get isAutoVerified =>
    driverVerifiedAt != null && driverVerifiedBy == null;

/// Human-readable verification status for UI display.
String get verificationStatusDisplay {
  if (isSuspended) return 'Suspended';
  switch (driverVerificationStatus) {
    case 'approved': return 'Verified';
    case 'pending': return 'Pending Review';
    case 'under_review': return 'Under Review';
    case 'documents_requested': return 'Documents Requested';
    case 'rejected': return 'Rejected';
    default: return 'Unknown';
  }
}
```

### B.2 Modify: `lib/features/bid/presentation/screens/bid_on_shipment_screen.dart`

```dart
// FIND the isVerified check and REPLACE with canBid:

// BEFORE:
if (!user.isVerified) {
  // Show verification prompt
}

// AFTER:
if (!user.canBid) {
  // Show specific reason
  String reason;
  if (user.role != 'Driver') {
    reason = 'You need to register as a driver to place bids.';
  } else if (user.isSuspended) {
    reason = 'Your account is currently suspended. Please contact support.';
  } else if (user.driverVerificationStatus == 'rejected') {
    reason = 'Your application was rejected. Please check your verification status for details.';
  } else if (user.driverVerificationStatus == 'documents_requested') {
    reason = 'Additional documents are needed. Please check your verification status.';
  } else {
    reason = 'Your account is pending verification. We\'ll notify you once approved.';
  }
  // Show dialog/banner with reason + navigate to Verification Status Screen
}
```

### B.3 Modify: `lib/features/bid/data/repositories/bid_repository_impl.dart`

```dart
// ADD client-side enforcement before the Supabase insert:

Future<void> submitBid(...) async {
  // Client-side check (server RLS is the real enforcer)
  final user = /* get current user */;
  if (!user.canBid) {
    throw Exception('Cannot bid: account not verified or suspended');
  }
  // ... existing bid submission logic
}
```

---

## PART C: Banking Dual-Write

### C.1 Modify: `lib/features/user/data/repositories/user_repository_impl.dart`

In the registration submission method, after saving banking to `users` table, also write to `driver_bank_accounts`:

```dart
// ADD after the existing updateUserInfo() call that saves banking to users table:

Future<void> _saveBankAccount({
  required String userId,
  required String bankName,
  required String bankCode,
  required String accountNumber,
  required String branchCode,
  required String firstName,
  required String lastName,
}) async {
  try {
    await _supabase.from('driver_bank_accounts').upsert({
      'driver_id': userId,
      'bank_name': bankName,
      'bank_code': bankCode,
      'account_number': accountNumber,
      'account_name': '$firstName $lastName',
      'is_primary': true,
      'is_active': true,
      'currency': 'ZAR',
      'is_verified': false,
      'verification_method': 'api',
    }, onConflict: 'driver_id, is_primary'); // Upsert on primary account
  } catch (e) {
    // Log but don't block registration — bank verification is async
    debugPrint('Warning: Failed to save to driver_bank_accounts: $e');
  }
}

// CALL this in the registration chain after registerAsDriver():
// Step 3 in the submission flow:
await _saveBankAccount(
  userId: userId,
  bankName: state.bankName,
  bankCode: state.bankCode, // You may need to add bankCode to state
  accountNumber: state.accountNumber,
  branchCode: state.branchCode,
  firstName: state.firstName,
  lastName: state.lastName,
);
```

**Note:** The `bank_code` field is available from the Paystack bank list dropdown (the same dropdown that populates `bankName`). You'll need to capture both the display name AND the Paystack bank code when the user selects a bank.

### C.2 Modify: `lib/features/user/presentation/widgets/banking_info_form.dart`

Ensure the bank dropdown captures both `bankName` and `bankCode`:

```dart
// When the user selects a bank from the Paystack list:
// Store BOTH:
//   - bankName (display): "First National Bank"
//   - bankCode (Paystack code): "110" (or whatever the code is)
//
// The bankCode is needed for the driver_bank_accounts table and for
// the Paystack bank verification Edge Function.
```

---

## PART D: Verification Status Screen (New Feature)

This is the biggest new piece. Drivers need to see where they stand.

### D.1 Create: `lib/features/user/presentation/state/verification_status_state.dart`

```dart
import 'package:flutter/foundation.dart';

enum OverallVerificationStatus {
  pending,
  underReview,
  documentsRequested,
  approved,
  rejected,
  suspended;

  factory OverallVerificationStatus.fromString(String? s) {
    switch (s) {
      case 'approved': return OverallVerificationStatus.approved;
      case 'under_review': return OverallVerificationStatus.underReview;
      case 'documents_requested': return OverallVerificationStatus.documentsRequested;
      case 'rejected': return OverallVerificationStatus.rejected;
      case 'suspended': return OverallVerificationStatus.suspended;
      default: return OverallVerificationStatus.pending;
    }
  }
}

@immutable
class VerificationStatusState {
  final OverallVerificationStatus overallStatus;
  final DateTime? verifiedAt;
  final String? verificationNotes;
  final List<DocVerificationItem> documents;
  final List<VehicleVerificationItem> vehicles;
  final BankVerificationItem? bankAccount;
  final bool isLoading;
  final String? error;

  const VerificationStatusState({
    this.overallStatus = OverallVerificationStatus.pending,
    this.verifiedAt,
    this.verificationNotes,
    this.documents = const [],
    this.vehicles = const [],
    this.bankAccount,
    this.isLoading = true,
    this.error,
  });

  bool get isFullyVerified => overallStatus == OverallVerificationStatus.approved;
  bool get hasRejectedDocs => documents.any((d) => d.needsReupload);
  bool get hasRejectedVehicles => vehicles.any((v) => v.status == 'rejected');

  int get approvedDocCount => documents.where((d) => d.status == 'approved').length;
  int get totalDocCount => documents.length;

  VerificationStatusState copyWith({
    OverallVerificationStatus? overallStatus,
    DateTime? verifiedAt,
    String? verificationNotes,
    List<DocVerificationItem>? documents,
    List<VehicleVerificationItem>? vehicles,
    BankVerificationItem? bankAccount,
    bool? isLoading,
    String? error,
  }) {
    return VerificationStatusState(
      overallStatus: overallStatus ?? this.overallStatus,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verificationNotes: verificationNotes ?? this.verificationNotes,
      documents: documents ?? this.documents,
      vehicles: vehicles ?? this.vehicles,
      bankAccount: bankAccount ?? this.bankAccount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

@immutable
class DocVerificationItem {
  final String id;
  final String docType;        // Normalized snake_case code
  final String displayLabel;   // Human-readable
  final String status;         // verification_status enum value
  final String? rejectionReason;
  final String? adminNotes;
  final String docUrl;

  const DocVerificationItem({
    required this.id,
    required this.docType,
    required this.displayLabel,
    required this.status,
    this.rejectionReason,
    this.adminNotes,
    required this.docUrl,
  });

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending' || status == 'under_review';
  bool get needsReupload => status == 'rejected' || status == 'documents_requested';

  factory DocVerificationItem.fromMap(Map<String, dynamic> map) {
    final code = DocType.normalize(map['doc_type'] ?? '');
    return DocVerificationItem(
      id: map['id'],
      docType: code,
      displayLabel: DocType.displayLabel(code),
      status: map['verification_status'] ?? 'pending',
      rejectionReason: map['rejection_reason'],
      adminNotes: map['admin_notes'],
      docUrl: map['doc_url'] ?? '',
    );
  }
}

@immutable
class VehicleVerificationItem {
  final String id;
  final String displayName;
  final String status;
  final String? rejectionReason;
  final String? photoUrl;

  const VehicleVerificationItem({
    required this.id,
    required this.displayName,
    required this.status,
    this.rejectionReason,
    this.photoUrl,
  });

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending' || status == 'under_review';

  factory VehicleVerificationItem.fromMap(Map<String, dynamic> map) {
    return VehicleVerificationItem(
      id: map['id'],
      displayName: '${map['make'] ?? ''} ${map['model'] ?? ''} (${map['license_plate'] ?? ''})',
      status: map['verification_status'] ?? 'pending',
      rejectionReason: map['rejection_reason'],
      photoUrl: map['photo_url'],
    );
  }
}

@immutable
class BankVerificationItem {
  final String id;
  final String bankName;
  final String maskedAccountNumber;
  final bool isVerified;
  final String? rejectionReason;
  final String? verificationMethod;

  const BankVerificationItem({
    required this.id,
    required this.bankName,
    required this.maskedAccountNumber,
    required this.isVerified,
    this.rejectionReason,
    this.verificationMethod,
  });

  factory BankVerificationItem.fromMap(Map<String, dynamic> map) {
    final accNum = map['account_number'] ?? '';
    final masked = accNum.length > 4
        ? '****${accNum.substring(accNum.length - 4)}'
        : accNum;
    return BankVerificationItem(
      id: map['id'],
      bankName: map['bank_name'] ?? '',
      maskedAccountNumber: masked,
      isVerified: map['is_verified'] ?? false,
      rejectionReason: map['rejection_reason'],
      verificationMethod: map['verification_method'],
    );
  }
}
```

### D.2 Create: `lib/features/user/presentation/providers/verification_status_provider.dart`

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../state/verification_status_state.dart';
import '../../domain/entities/doc_type_map.dart';

class VerificationStatusNotifier extends StateNotifier<VerificationStatusState> {
  final SupabaseClient _supabase;
  final String _userId;

  RealtimeChannel? _userChannel;
  RealtimeChannel? _docsChannel;
  RealtimeChannel? _vehiclesChannel;

  VerificationStatusNotifier(this._supabase, this._userId)
      : super(const VerificationStatusState()) {
    _loadAll();
    _subscribeRealtime();
  }

  // ── Initial Load ──

  Future<void> _loadAll() async {
    state = state.copyWith(isLoading: true);
    try {
      await Future.wait([
        _loadDriverStatus(),
        _loadDocuments(),
        _loadVehicles(),
        _loadBankAccount(),
      ]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadDriverStatus() async {
    final row = await _supabase
        .from('users')
        .select('driver_verification_status, driver_verified_at, verification_notes, is_suspended')
        .eq('id', _userId)
        .single();

    state = state.copyWith(
      overallStatus: OverallVerificationStatus.fromString(
        row['is_suspended'] == true ? 'suspended' : row['driver_verification_status'],
      ),
      verifiedAt: row['driver_verified_at'] != null
          ? DateTime.parse(row['driver_verified_at'])
          : null,
      verificationNotes: row['verification_notes'],
    );
  }

  Future<void> _loadDocuments() async {
    final rows = await _supabase
        .from('driver_docs')
        .select()
        .eq('driver_id', _userId)
        .order('created_at');

    state = state.copyWith(
      documents: rows.map<DocVerificationItem>((r) => DocVerificationItem.fromMap(r)).toList(),
    );
  }

  Future<void> _loadVehicles() async {
    final rows = await _supabase
        .from('vehicles')
        .select()
        .eq('driver_id', _userId)
        .order('created_at');

    state = state.copyWith(
      vehicles: rows.map<VehicleVerificationItem>((r) => VehicleVerificationItem.fromMap(r)).toList(),
    );
  }

  Future<void> _loadBankAccount() async {
    final rows = await _supabase
        .from('driver_bank_accounts')
        .select()
        .eq('driver_id', _userId)
        .eq('is_primary', true)
        .eq('is_active', true)
        .limit(1);

    state = state.copyWith(
      bankAccount: rows.isNotEmpty ? BankVerificationItem.fromMap(rows.first) : null,
    );
  }

  // ── Realtime Subscriptions ──

  void _subscribeRealtime() {
    // Listen for driver status changes
    _userChannel = _supabase.channel('verification-user-$_userId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'users',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: _userId,
        ),
        callback: (payload) => _loadDriverStatus(),
      )
      ..subscribe();

    // Listen for document status changes
    _docsChannel = _supabase.channel('verification-docs-$_userId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'driver_docs',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'driver_id',
          value: _userId,
        ),
        callback: (payload) => _loadDocuments(),
      )
      ..subscribe();

    // Listen for vehicle status changes
    _vehiclesChannel = _supabase.channel('verification-vehicles-$_userId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'vehicles',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'driver_id',
          value: _userId,
        ),
        callback: (payload) => _loadVehicles(),
      )
      ..subscribe();
  }

  // ── Document Re-upload ──

  /// Called when driver re-uploads a rejected document.
  /// Resets the document status to 'pending' with a new URL.
  Future<void> reuploadDocument(String documentId, String newDocUrl) async {
    await _supabase.from('driver_docs').update({
      'doc_url': newDocUrl,
      'verification_status': 'pending',
      'rejection_reason': null,
      'admin_notes': null,
      'modified_at': DateTime.now().toIso8601String(),
    }).eq('id', documentId);

    // Realtime subscription will auto-refresh the list,
    // but also refresh immediately for snappy UX
    await _loadDocuments();
  }

  // ── Refresh ──

  Future<void> refresh() => _loadAll();

  // ── Cleanup ──

  @override
  void dispose() {
    _userChannel?.unsubscribe();
    _docsChannel?.unsubscribe();
    _vehiclesChannel?.unsubscribe();
    super.dispose();
  }
}

// ── Riverpod Providers ──

final verificationStatusProvider = StateNotifierProvider.autoDispose
    .family<VerificationStatusNotifier, VerificationStatusState, String>(
  (ref, userId) {
    final supabase = Supabase.instance.client;
    return VerificationStatusNotifier(supabase, userId);
  },
);
```

### D.3 Create: `lib/features/user/presentation/screens/verification_status_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/verification_status_provider.dart';
import '../state/verification_status_state.dart';
import '../widgets/verification_item_tile.dart';
import '../widgets/document_reupload_sheet.dart';

class VerificationStatusScreen extends ConsumerWidget {
  final String userId;

  const VerificationStatusScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verificationStatusProvider(userId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Verification Status')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(verificationStatusProvider(userId).notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Overall Status Banner ──
                  _buildStatusBanner(context, state),
                  const SizedBox(height: 24),

                  // ── Documents Section ──
                  if (state.documents.isNotEmpty) ...[
                    Text('Documents', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...state.documents.map((doc) => VerificationItemTile(
                      icon: Icons.description_outlined,
                      label: doc.displayLabel,
                      status: doc.status,
                      rejectionReason: doc.rejectionReason,
                      onReupload: doc.needsReupload
                          ? () => _showReuploadSheet(context, ref, doc)
                          : null,
                    )),
                    const SizedBox(height: 16),
                  ],

                  // ── Vehicles Section ──
                  if (state.vehicles.isNotEmpty) ...[
                    Text('Vehicles', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...state.vehicles.map((v) => VerificationItemTile(
                      icon: Icons.local_shipping_outlined,
                      label: v.displayName,
                      status: v.status,
                      rejectionReason: v.rejectionReason,
                    )),
                    const SizedBox(height: 16),
                  ],

                  // ── Banking Section ──
                  if (state.bankAccount != null) ...[
                    Text('Banking', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    VerificationItemTile(
                      icon: Icons.account_balance_outlined,
                      label: '${state.bankAccount!.bankName} (${state.bankAccount!.maskedAccountNumber})',
                      status: state.bankAccount!.isVerified ? 'approved' : 'pending',
                      rejectionReason: state.bankAccount!.rejectionReason,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, VerificationStatusState state) {
    final theme = Theme.of(context);

    Color bannerColor;
    IconData bannerIcon;
    String title;
    String subtitle;
    Widget? cta;

    switch (state.overallStatus) {
      case OverallVerificationStatus.approved:
        bannerColor = Colors.green;
        bannerIcon = Icons.verified;
        title = 'Account Verified';
        subtitle = 'You can now bid on available loads!';
        cta = ElevatedButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed('/find-loads'),
          child: const Text('Browse Available Loads'),
        );
        break;
      case OverallVerificationStatus.pending:
      case OverallVerificationStatus.underReview:
        bannerColor = Colors.orange;
        bannerIcon = Icons.hourglass_top;
        title = 'Under Review';
        subtitle = 'Your application is being reviewed. We\'ll notify you when it\'s complete.';
        break;
      case OverallVerificationStatus.documentsRequested:
        bannerColor = Colors.orange;
        bannerIcon = Icons.upload_file;
        title = 'Documents Needed';
        subtitle = 'Please re-upload the documents marked below.';
        break;
      case OverallVerificationStatus.rejected:
        bannerColor = Colors.red;
        bannerIcon = Icons.cancel_outlined;
        title = 'Application Rejected';
        subtitle = state.verificationNotes ?? 'Please review the details below and contact support if needed.';
        break;
      case OverallVerificationStatus.suspended:
        bannerColor = Colors.grey;
        bannerIcon = Icons.block;
        title = 'Account Suspended';
        subtitle = state.verificationNotes ?? 'Please contact support for more information.';
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: bannerColor.withOpacity(0.3)),
      ),
      color: bannerColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(bannerIcon, size: 48, color: bannerColor),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleLarge?.copyWith(color: bannerColor)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            if (state.documents.isNotEmpty && !state.isFullyVerified) ...[
              const SizedBox(height: 8),
              Text(
                '${state.approvedDocCount} of ${state.totalDocCount} documents verified',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (cta != null) ...[const SizedBox(height: 16), cta],
          ],
        ),
      ),
    );
  }

  void _showReuploadSheet(BuildContext context, WidgetRef ref, DocVerificationItem doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DocumentReuploadSheet(
        docItem: doc,
        onUploadComplete: (newUrl) {
          ref.read(verificationStatusProvider(userId).notifier)
              .reuploadDocument(doc.id, newUrl);
        },
      ),
    );
  }
}
```

### D.4 Create: `lib/features/user/presentation/widgets/verification_item_tile.dart`

```dart
import 'package:flutter/material.dart';

class VerificationItemTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String status;
  final String? rejectionReason;
  final VoidCallback? onReupload;

  const VerificationItemTile({
    super.key,
    required this.icon,
    required this.label,
    required this.status,
    this.rejectionReason,
    this.onReupload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (statusIcon, statusColor, statusLabel) = _statusDisplay();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(label, style: theme.textTheme.bodyLarge),
                  ),
                  Icon(statusIcon, size: 20, color: statusColor),
                  const SizedBox(width: 4),
                  Text(statusLabel, style: theme.textTheme.labelSmall?.copyWith(color: statusColor)),
                ],
              ),
              if (rejectionReason != null && (status == 'rejected' || status == 'documents_requested')) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rejectionReason!,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (onReupload != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onReupload,
                    icon: const Icon(Icons.upload_outlined, size: 18),
                    label: const Text('Re-upload'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      side: BorderSide(color: Colors.orange.shade300),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color, String) _statusDisplay() {
    switch (status) {
      case 'approved':
        return (Icons.check_circle, Colors.green, 'Approved');
      case 'rejected':
        return (Icons.cancel, Colors.red, 'Rejected');
      case 'documents_requested':
        return (Icons.upload_file, Colors.orange, 'Re-upload');
      case 'under_review':
        return (Icons.visibility, Colors.blue, 'Reviewing');
      case 'pending':
      default:
        return (Icons.hourglass_top, Colors.grey, 'Pending');
    }
  }
}
```

### D.5 Create: `lib/features/user/presentation/widgets/document_reupload_sheet.dart`

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../state/verification_status_state.dart';

/// Bottom sheet that lets a driver re-upload a rejected document.
/// Reuses the same upload logic from driver_profile_provider.dart.
class DocumentReuploadSheet extends StatefulWidget {
  final DocVerificationItem docItem;
  final void Function(String newDocUrl) onUploadComplete;

  const DocumentReuploadSheet({
    super.key,
    required this.docItem,
    required this.onUploadComplete,
  });

  @override
  State<DocumentReuploadSheet> createState() => _DocumentReuploadSheetState();
}

class _DocumentReuploadSheetState extends State<DocumentReuploadSheet> {
  bool _isUploading = false;
  String? _error;

  Future<void> _pickAndUpload(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    setState(() { _isUploading = true; _error = null; });

    try {
      // Reuse existing upload logic from user_repository_impl.dart:
      // 1. Compress if > 1MB
      // 2. Base64 encode
      // 3. POST to /storage-proxy Edge Function
      // 4. Get back the Supabase Storage URL
      //
      // TODO: Extract the upload method from UserRepositoryImpl into a shared
      //       DocumentUploadService so it can be reused here without duplication.
      //
      // For now, call the same method:
      final newUrl = await _uploadDocument(File(picked.path), widget.docItem.docType);

      widget.onUploadComplete(newUrl);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _error = 'Upload failed. Please try again.'; _isUploading = false; });
    }
  }

  Future<String> _uploadDocument(File file, String docType) async {
    // TODO: Wire up to existing upload infrastructure.
    // This should call the same Edge Function /storage-proxy
    // with the same compression + retry logic used during registration.
    throw UnimplementedError('Wire up to existing document upload service');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Re-upload ${widget.docItem.displayLabel}', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (widget.docItem.rejectionReason != null)
            Text(
              'Reason: ${widget.docItem.rejectionReason}',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
            ),
          const SizedBox(height: 16),
          if (_isUploading)
            const Center(child: CircularProgressIndicator())
          else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickAndUpload(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickAndUpload(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.red.shade700)),
          ],
        ],
      ),
    );
  }
}
```

---

## PART E: Notification Handling

### E.1 Modify: `lib/core/services/fcm_service.dart`

Add handlers for driver-bound verification notifications:

```dart
// In the notification handling method (typically onMessage / onMessageOpenedApp):
// ADD these cases to the existing notification type switch:

case 'driver_approved':
case 'driver_auto_verified':
  // Navigate to Find Loads screen (driver is now verified)
  _navigateTo('/find-loads');
  break;

case 'driver_rejected':
case 'document_rejected':
case 'document_reupload_requested':
case 'documents_requested':  // driver-level request
  // Navigate to Verification Status Screen
  _navigateTo('/verification-status');
  break;

case 'document_approved':
case 'vehicle_approved':
case 'vehicle_rejected':
case 'bank_verification_completed':
  // Navigate to Verification Status Screen
  _navigateTo('/verification-status');
  break;
```

### E.2 Add navigation route

Add the Verification Status Screen route to your navigator:

```dart
// In your route configuration (e.g., MaterialApp routes or GoRouter):
'/verification-status': (context) => VerificationStatusScreen(
  userId: /* current user ID from auth state */,
),
```

---

## PART F: UI Entry Points

### F.1 Modify: `lib/core/components/app_side_menu.dart`

Add a "Verification Status" menu item for unverified drivers:

```dart
// ADD inside the side menu builder, after "Register as Driver" or "Driver Profile":

if (user.role == 'Driver' && !user.canBid) ...[
  ListTile(
    leading: Icon(
      Icons.verified_user_outlined,
      color: user.driverVerificationStatus == 'rejected' ? Colors.red : Colors.orange,
    ),
    title: const Text('Verification Status'),
    subtitle: Text(user.verificationStatusDisplay),
    onTap: () {
      Navigator.pop(context); // close drawer
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => VerificationStatusScreen(userId: user.id),
      ));
    },
  ),
],
```

### F.2 Modify: `lib/features/user/presentation/screens/driver_profile_screen.dart`

After successful registration, navigate to Verification Status Screen instead of just going to home:

```dart
// FIND the post-registration navigation (after "Register" button success):
// REPLACE with:

if (mounted) {
  Navigator.pushReplacement(context, MaterialPageRoute(
    builder: (_) => VerificationStatusScreen(userId: userId),
  ));
}
```

### F.3 Modify: `lib/features/user/presentation/widgets/document_upload_tile.dart`

Show verification status badges on document tiles in edit mode:

```dart
// ADD after the existing upload status indicator:

if (!isRegistrationMode && document.verificationStatus != 'pending') ...[
  // Show verification badge
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: _verificationColor(document.verificationStatus).withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      _verificationLabel(document.verificationStatus),
      style: TextStyle(
        fontSize: 10,
        color: _verificationColor(document.verificationStatus),
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
],

// Helper methods:
Color _verificationColor(String status) {
  switch (status) {
    case 'approved': return Colors.green;
    case 'rejected': return Colors.red;
    case 'documents_requested': return Colors.orange;
    case 'under_review': return Colors.blue;
    default: return Colors.grey;
  }
}

String _verificationLabel(String status) {
  switch (status) {
    case 'approved': return 'VERIFIED';
    case 'rejected': return 'REJECTED';
    case 'documents_requested': return 'RE-UPLOAD';
    case 'under_review': return 'REVIEWING';
    default: return 'PENDING';
  }
}
```

---

## FILE SUMMARY

| Action | File Path | What Changes |
|--------|-----------|--------------|
| **CREATE** | `lib/features/user/domain/entities/doc_type_map.dart` | DocType constants + normalize() + displayLabel() |
| **CREATE** | `lib/features/user/presentation/state/verification_status_state.dart` | VerificationStatusState + item classes |
| **CREATE** | `lib/features/user/presentation/providers/verification_status_provider.dart` | StateNotifier with Supabase Realtime subscriptions |
| **CREATE** | `lib/features/user/presentation/screens/verification_status_screen.dart` | Full verification status screen |
| **CREATE** | `lib/features/user/presentation/widgets/verification_item_tile.dart` | Reusable status tile widget |
| **CREATE** | `lib/features/user/presentation/widgets/document_reupload_sheet.dart` | Re-upload bottom sheet |
| **MODIFY** | `lib/features/user/domain/entities/document_entity.dart` | Add verification fields + fromMap/toMap |
| **MODIFY** | `lib/features/user/domain/entities/user_entity.dart` | Add canBid, isAutoVerified, verificationStatusDisplay |
| **MODIFY** | `lib/features/user/data/repositories/user_repository_impl.dart` | Normalize doc_types + dual-write banking + read verification fields |
| **MODIFY** | `lib/features/user/presentation/providers/driver_profile_provider.dart` | Use DocType codes for validation |
| **MODIFY** | `lib/features/user/presentation/screens/driver_profile_screen.dart` | Post-registration redirect to verification screen |
| **MODIFY** | `lib/features/user/presentation/widgets/document_upload_tile.dart` | Show verification badges |
| **MODIFY** | `lib/features/user/presentation/widgets/banking_info_form.dart` | Capture bankCode alongside bankName |
| **MODIFY** | `lib/features/bid/presentation/screens/bid_on_shipment_screen.dart` | Replace isVerified with canBid + specific reason messages |
| **MODIFY** | `lib/features/bid/data/repositories/bid_repository_impl.dart` | Add canBid client-side check |
| **MODIFY** | `lib/core/services/fcm_service.dart` | Handle new verification notification types |
| **MODIFY** | `lib/core/components/app_side_menu.dart` | Add "Verification Status" menu item |
