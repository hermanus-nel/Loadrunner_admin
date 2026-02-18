# SPEC 2: LoadRunner Admin App — Oversight for Automated Driver Registration

**Purpose:** Step-by-step coding spec for the Admin app changes needed to support automated driver registration with full admin oversight.  
**Prerequisite:** Run the database migration (SPEC_DATABASE_MIGRATION.sql) BEFORE coding either app.  
**Key Principle:** The admin app already has comprehensive review infrastructure. These changes are additive — nothing breaks, admins gain visibility into auto-verification while retaining full override capability.

---

## PART A: Update Auto-Verify Check to Use Normalized Doc Types

The existing `DocumentReviewRepository.approveDocument()` method runs an auto-verify check after each document approval. Currently it looks for `doc_type IN ('id_document', 'id_front')` and `doc_type = 'license_front'` — but the DB has human-readable strings like `"ID Document"`. After the database migration normalizes all doc_types, this code will work correctly. However, we should also make it robust against both formats during the transition.

### A.1 Modify: `lib/features/users/data/repositories/document_review_repository.dart`

In the `_checkAutoVerify()` or equivalent method after document approval:

```dart
// CURRENT auto-verify check (works after migration):
// Fetch all docs for driver
// Check: has approved doc where doc_type IN ('id_document', 'id_front')
// Check: has approved doc where doc_type = 'license_front'

// ENHANCED: Accept both legacy and normalized formats during transition
Future<bool> _checkAutoVerify(String driverId) async {
  final docs = await _supabase
      .from('driver_docs')
      .select('doc_type, verification_status')
      .eq('driver_id', driverId)
      .eq('verification_status', 'approved');

  final approvedTypes = docs.map<String>((d) => d['doc_type'] as String).toSet();

  // Check ID Document (accept both formats)
  final hasId = approvedTypes.contains('id_document') ||
                approvedTypes.contains('id_front') ||
                approvedTypes.contains('ID Document');

  // Check License (accept both formats)
  final hasLicense = approvedTypes.contains('license_front') ||
                     approvedTypes.contains("Driver's License");

  return hasId && hasLicense;
}
```

**Note:** Once the database migration is complete AND the LoadRunner app is updated, only normalized codes will exist. The legacy checks can be removed after a transition period.

The actual auto-approval is now handled by the database trigger `trg_auto_verify_driver` (see SPEC_DATABASE_MIGRATION.sql), so the admin app's auto-verify check becomes a secondary confirmation. The trigger fires server-side when any document is updated to `approved`, so even if the admin app's check misses something, the database handles it.

---

## PART B: Identify Auto-Verified Drivers

### B.1 Modify: `lib/features/users/domain/entities/driver_profile.dart`

Add a computed property to distinguish auto-verified from admin-verified:

```dart
// ADD to the existing DriverProfile class:

/// Whether this driver was verified by the auto-verify system (not by an admin).
/// The DB trigger sets driver_verified_by = NULL for auto-actions,
/// while admin approvals always set it to the admin's real UUID.
bool get isAutoVerified =>
    driverVerificationStatus == 'approved' &&
    driverVerifiedBy == null;

/// Whether this driver was manually approved by an admin.
bool get isAdminVerified =>
    driverVerificationStatus == 'approved' &&
    driverVerifiedBy != null;

/// Badge label for the driver list.
String get verificationBadgeLabel {
  if (isSuspended) return 'Suspended';
  switch (driverVerificationStatus) {
    case 'approved':
      return isAutoVerified ? 'Auto-Verified' : 'Admin Approved';
    case 'pending': return 'Pending';
    case 'under_review': return 'Under Review';
    case 'documents_requested': return 'Docs Requested';
    case 'rejected': return 'Rejected';
    default: return 'Unknown';
  }
}

/// Badge colour for the driver list.
Color get verificationBadgeColor {
  if (isSuspended) return Colors.grey;
  switch (driverVerificationStatus) {
    case 'approved':
      return isAutoVerified ? const Color(0xFF0891B2) : Colors.green; // Teal for auto, green for admin
    case 'pending': return Colors.orange;
    case 'under_review': return Colors.blue;
    case 'documents_requested': return Colors.orange;
    case 'rejected': return Colors.red;
    default: return Colors.grey;
  }
}
```

### B.2 Modify: `lib/features/users/data/models/driver_model.dart`

Ensure the light driver model (used in list screen) exposes `driver_verified_by`:

```dart
// ADD to the existing fromMap:
// Ensure you read driver_verified_by from the query result
final driverVerifiedBy = map['driver_verified_by'] as String?;
```

### B.3 Modify: `lib/features/users/presentation/providers/drivers_providers.dart`

Add filter chips for auto-verified and flagged drivers:

```dart
// CURRENT filter options:
// All | Pending | Approved | Rejected

// NEW filter options:
enum DriverStatusFilter {
  all,
  pending,
  underReview,
  autoVerified,    // NEW
  adminApproved,   // NEW (split from 'approved')
  rejected,
  suspended,       // NEW
}

// In the fetch method, adjust the query based on filter:
Future<void> fetchDrivers({DriverStatusFilter filter = DriverStatusFilter.all}) async {
  var query = _supabase.from('users').select().eq('role', 'Driver');

  switch (filter) {
    case DriverStatusFilter.all:
      break;
    case DriverStatusFilter.pending:
      query = query.inFilter('driver_verification_status', ['pending', 'under_review']);
      break;
    case DriverStatusFilter.underReview:
      query = query.eq('driver_verification_status', 'under_review');
      break;
    case DriverStatusFilter.autoVerified:
      query = query.eq('driver_verification_status', 'approved');
      // Post-filter: driver_verified_by IS NULL or system UUID
      // (Supabase doesn't support IS NULL in .eq, so filter in Dart)
      break;
    case DriverStatusFilter.adminApproved:
      query = query.eq('driver_verification_status', 'approved');
      // Post-filter: driver_verified_by IS NOT NULL and not system UUID
      break;
    case DriverStatusFilter.rejected:
      query = query.eq('driver_verification_status', 'rejected');
      break;
    case DriverStatusFilter.suspended:
      query = query.eq('is_suspended', true);
      break;
  }

  final results = await query.order('created_at', ascending: false);

  // Post-filter for auto vs admin verified
  List<Map<String, dynamic>> filtered = results;
  if (filter == DriverStatusFilter.autoVerified) {
    filtered = results.where((r) =>
      r['driver_verified_by'] == null
    ).toList();
  } else if (filter == DriverStatusFilter.adminApproved) {
    filtered = results.where((r) =>
      r['driver_verified_by'] != null
    ).toList();
  }

  // ... rest of existing pagination logic
}

// Status counts for filter badges:
Future<Map<DriverStatusFilter, int>> fetchStatusCounts() async {
  final all = await _supabase
      .from('users')
      .select('driver_verification_status, driver_verified_by, is_suspended')
      .eq('role', 'Driver');

  return {
    DriverStatusFilter.all: all.length,
    DriverStatusFilter.pending: all.where((r) =>
        r['driver_verification_status'] == 'pending' ||
        r['driver_verification_status'] == 'under_review').length,
    DriverStatusFilter.autoVerified: all.where((r) =>
        r['driver_verification_status'] == 'approved' &&
        r['driver_verified_by'] == null).length,
    DriverStatusFilter.adminApproved: all.where((r) =>
        r['driver_verification_status'] == 'approved' &&
        r['driver_verified_by'] != null).length,
    DriverStatusFilter.rejected: all.where((r) =>
        r['driver_verification_status'] == 'rejected').length,
    DriverStatusFilter.suspended: all.where((r) =>
        r['is_suspended'] == true).length,
  };
}
```

---

## PART C: Document Queue — Exclude Auto-Verified

### C.1 Modify: `lib/features/users/data/repositories/document_review_repository.dart`

Update the document queue query to optionally exclude documents from already-verified drivers:

```dart
// ADD a parameter to control the filter:

Future<List<DocumentQueueItem>> fetchDocumentQueue({
  bool showAutoVerified = false,  // NEW parameter
  String? docTypeFilter,
  int page = 0,
  int pageSize = 20,
}) async {
  var query = _supabase
      .from('driver_docs')
      .select('''
        id, doc_type, doc_url, verification_status, created_at, driver_id,
        users!inner(
          id, first_name, last_name, phone_number, profile_photo_url,
          driver_verification_status, driver_verified_by, created_at
        )
      ''')
      .inFilter('verification_status', ['pending', 'under_review']);

  // Exclude docs from auto-verified drivers (unless toggled on)
  if (!showAutoVerified) {
    query = query.neq('users.driver_verification_status', 'approved');
  }

  if (docTypeFilter != null) {
    query = query.eq('doc_type', docTypeFilter);
  }

  final results = await query
      .order('created_at', ascending: true) // Oldest first
      .range(page * pageSize, (page + 1) * pageSize - 1);

  return results.map<DocumentQueueItem>((r) => DocumentQueueItem.fromMap(r)).toList();
}
```

### C.2 Modify: `lib/features/users/presentation/screens/document_queue_screen.dart`

Add a toggle switch to show/hide auto-verified driver docs:

```dart
// ADD to the app bar or filter area:

Switch(
  value: showAutoVerified,
  onChanged: (val) {
    setState(() { showAutoVerified = val; });
    ref.read(documentQueueNotifierProvider.notifier).refresh(showAutoVerified: val);
  },
),
const Text('Include verified'),
```

---

## PART D: Revoke Auto-Verification Action

### D.1 Modify: `lib/features/users/data/repositories/drivers_repository_impl.dart`

Add a method to revoke auto-verification:

```dart
/// Revoke an auto-verified driver's status and send back to under_review.
/// Only callable when driver was auto-verified (driver_verified_by is NULL or system UUID).
Future<void> revokeAutoVerification({
  required String driverId,
  required String adminId,
  required String reason,
  String? notes,
}) async {
  // 1. Call the same update_driver_verification RPC
  await _supabase.rpc('update_driver_verification', params: {
    'p_driver_id': driverId,
    'p_admin_id': adminId,
    'p_new_status': 'under_review',
    'p_reason': reason,
    'p_notes': notes ?? 'Auto-verification revoked by admin.',
  });

  // 2. Clear the verified_at timestamp
  await _supabase.from('users').update({
    'driver_verified_at': null,
    'driver_verified_by': null,
  }).eq('id', driverId);

  // 3. Notify the driver
  await _supabase.from('notifications').insert({
    'user_id': driverId,
    'type': 'general',
    'message': 'Your driver verification is under review. An admin is reviewing your application. Reason: $reason',
    'delivery_method': 'both',
    'sent_at': DateTime.now().toIso8601String(),
  });

  // 4. Log audit
  await _supabase.from('admin_audit_logs').insert({
    'admin_id': adminId,
    'action': 'revoke_auto_verification',
    'target_type': 'user',
    'target_id': driverId,
    'details': {
      'previous_status': 'approved',
      'new_status': 'under_review',
      'reason': reason,
      'notes': notes,
    },
  });
}
```

### D.2 Modify: `lib/features/users/presentation/screens/driver_profile_screen.dart`

Add the revoke button to the action bar when the driver is auto-verified:

```dart
// In the action bar builder, ADD a condition for auto-verified drivers:

if (profile.isAutoVerified) ...[
  // Show revoke button alongside existing actions
  OutlinedButton.icon(
    onPressed: () => _showRevokeDialog(context, ref, profile),
    icon: const Icon(Icons.undo, size: 18),
    label: const Text('Revoke Auto-Verification'),
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.orange.shade700,
      side: BorderSide(color: Colors.orange.shade300),
    ),
  ),
],

// Dialog method:
void _showRevokeDialog(BuildContext context, WidgetRef ref, DriverProfile profile) {
  final reasonController = TextEditingController();
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Revoke Auto-Verification'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This will set ${profile.fullName}\'s status back to "Under Review".'),
          const SizedBox(height: 16),
          TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Why are you revoking auto-verification?',
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (reasonController.text.isEmpty) return;
            Navigator.pop(context);
            await ref.read(driversRepositoryProvider).revokeAutoVerification(
              driverId: profile.id,
              adminId: /* current admin ID */,
              reason: reasonController.text,
            );
            ref.invalidate(driverProfileControllerProvider(profile.id));
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Revoke'),
        ),
      ],
    ),
  );
}
```

---

## PART E: Approval History — Show Auto-Verify Entries

### E.1 Modify: `lib/features/users/presentation/screens/driver_profile_screen.dart`

In the Approval History section, identify and style auto-verify entries differently:

```dart
// When building approval history timeline entries:
// Check if admin_id is the system user UUID

Widget _buildHistoryEntry(ApprovalHistoryItem item) {
  final isAutoAction = item.adminId == null;

  return ListTile(
    leading: CircleAvatar(
      backgroundColor: isAutoAction ? Colors.teal.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
      child: Icon(
        isAutoAction ? Icons.smart_toy_outlined : Icons.admin_panel_settings_outlined,
        color: isAutoAction ? Colors.teal : Colors.blue,
        size: 20,
      ),
    ),
    title: Text(
      isAutoAction
          ? 'Auto-Verification Engine'
          : item.adminName ?? 'Admin',
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${item.previousStatus ?? '—'} → ${item.newStatus}'),
        if (item.reason != null) Text(item.reason!, style: const TextStyle(fontSize: 12)),
        if (item.notes != null) Text(item.notes!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          _formatDate(item.createdAt),
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    ),
  );
}
```

---

## PART F: Read Banking from `driver_bank_accounts`

### F.1 Modify: `lib/features/users/data/repositories/drivers_profile_repository.dart`

Update the bank account fetch to show Paystack verification details:

```dart
// CURRENT: Reads bank info from users table (legacy)
// NEW: Also read from driver_bank_accounts for verification status

Future<DriverBankAccount?> fetchBankAccount(String driverId) async {
  final rows = await _supabase
      .from('driver_bank_accounts')
      .select()
      .eq('driver_id', driverId)
      .eq('is_primary', true)
      .eq('is_active', true)
      .limit(1);

  if (rows.isEmpty) {
    // Fall back to legacy users table fields
    final user = await _supabase
        .from('users')
        .select('bank_name, account_number, branch_code')
        .eq('id', driverId)
        .single();

    if (user['bank_name'] == null) return null;

    return DriverBankAccount(
      id: '',
      driverId: driverId,
      bankName: user['bank_name'] ?? '',
      accountNumber: user['account_number'] ?? '',
      isVerified: false,
      verificationMethod: 'none',
      verificationNotes: 'Legacy: stored on users table only',
    );
  }

  return DriverBankAccount.fromMap(rows.first);
}
```

### F.2 Modify: `lib/features/users/domain/entities/driver_bank_account.dart`

Ensure the entity includes all Paystack verification fields:

```dart
// ADD/VERIFY these fields exist:
class DriverBankAccount {
  final String id;
  final String driverId;
  final String bankName;
  final String? bankCode;
  final String accountNumber;
  final String? accountName;          // From Paystack resolve
  final String? paystackRecipientCode;
  final bool isVerified;
  final DateTime? verifiedAt;
  final String? verificationMethod;   // 'api', 'manual', 'override'
  final String? verificationNotes;
  final String? rejectionReason;
  final DateTime? rejectedAt;
  final bool isPrimary;
  final bool isActive;
  final String currency;

  // ...

  /// Display status for admin view
  String get verificationStatusLabel {
    if (isVerified) return 'Verified via ${verificationMethod ?? 'unknown'}';
    if (rejectionReason != null) return 'Failed: $rejectionReason';
    return 'Pending verification';
  }
}
```

### F.3 Modify: `lib/features/users/presentation/screens/driver_profile_screen.dart`

Update the Bank Account section to show verification status:

```dart
// In the Bank Account section of the driver profile:
// ENHANCE to show Paystack verification details

Widget _buildBankSection(DriverBankAccount? bank) {
  if (bank == null) {
    return const ListTile(
      leading: Icon(Icons.account_balance, color: Colors.grey),
      title: Text('No banking information'),
    );
  }

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance),
              const SizedBox(width: 12),
              Text(bank.bankName, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              // Verification badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: bank.isVerified ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  bank.isVerified ? 'Verified' : (bank.rejectionReason != null ? 'Failed' : 'Pending'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: bank.isVerified ? Colors.green : (bank.rejectionReason != null ? Colors.red : Colors.orange),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow('Account', _maskAccount(bank.accountNumber)),
          if (bank.accountName != null)
            _infoRow('Account Name', bank.accountName!),
          _infoRow('Currency', bank.currency),
          if (bank.verificationMethod != null)
            _infoRow('Verification', bank.verificationStatusLabel),
          if (bank.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Paystack: ${bank.rejectionReason}',
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
```

---

## PART G: Dashboard Stats (Optional Enhancement)

### G.1 Create: `lib/features/dashboard/presentation/widgets/registration_overview_card.dart`

```dart
// A card showing registration stats for the admin dashboard.
// Queries:

Future<Map<String, int>> fetchRegistrationStats({
  required DateTime since,
}) async {
  final drivers = await _supabase
      .from('users')
      .select('driver_verification_status, driver_verified_by, is_suspended, created_at')
      .eq('role', 'Driver')
      .gte('created_at', since.toIso8601String());

  final autoVerified = drivers.where((d) =>
    d['driver_verification_status'] == 'approved' &&
    d['driver_verified_by'] == null).length;

  final adminApproved = drivers.where((d) =>
    d['driver_verification_status'] == 'approved' &&
    d['driver_verified_by'] != null).length;

  return {
    'total': drivers.length,
    'autoVerified': autoVerified,
    'adminApproved': adminApproved,
    'pending': drivers.where((d) =>
      d['driver_verification_status'] == 'pending' ||
      d['driver_verification_status'] == 'under_review').length,
    'rejected': drivers.where((d) =>
      d['driver_verification_status'] == 'rejected').length,
    'suspended': drivers.where((d) => d['is_suspended'] == true).length,
  };
}

// Display as stat cards:
// Total | Auto-Verified | Pending Review | Rejected
// With auto-verify rate: autoVerified / (autoVerified + adminApproved) * 100
```

---

## FILE SUMMARY

| Action | File Path | What Changes |
|--------|-----------|--------------|
| **MODIFY** | `lib/features/users/domain/entities/driver_profile.dart` | Add `isAutoVerified`, `isAdminVerified`, `verificationBadgeLabel`, `verificationBadgeColor` |
| **MODIFY** | `lib/features/users/domain/entities/driver_bank_account.dart` | Add Paystack verification fields + `verificationStatusLabel` |
| **MODIFY** | `lib/features/users/data/repositories/document_review_repository.dart` | Accept both legacy and normalized doc_types in auto-verify; filter queue by verified status |
| **MODIFY** | `lib/features/users/data/repositories/drivers_repository_impl.dart` | Add `revokeAutoVerification()` method |
| **MODIFY** | `lib/features/users/data/repositories/drivers_profile_repository.dart` | Read bank from `driver_bank_accounts` with legacy fallback |
| **MODIFY** | `lib/features/users/presentation/providers/drivers_providers.dart` | Add `autoVerified`, `adminApproved`, `suspended` filter chips; add `fetchStatusCounts()` |
| **MODIFY** | `lib/features/users/presentation/screens/driver_profile_screen.dart` | Revoke button for auto-verified; auto-verify entries in history; enhanced bank section |
| **MODIFY** | `lib/features/users/presentation/screens/document_queue_screen.dart` | Toggle to show/hide auto-verified driver docs |
| **CREATE** | `lib/features/dashboard/presentation/widgets/registration_overview_card.dart` | Dashboard stats widget (optional) |
