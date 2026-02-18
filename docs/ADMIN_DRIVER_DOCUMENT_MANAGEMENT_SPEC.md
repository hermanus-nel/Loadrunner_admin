# LoadRunner Admin - Driver Document Management Specification

**Version:** 1.0
**Date:** February 17, 2026

---

## 1. Overview

This specification defines how admin users review, approve, reject, and request re-submission of driver documents in the LoadRunner Admin app. It covers the verification workflow, pre-defined message templates for communicating with drivers, and the notification delivery channels (push + in-app).

---

## 2. Document Types

### 2.1 Personal Documents (uploaded in Personal Info step)

| Document | Required | DB `doc_type` value |
|---|---|---|
| ID Document (SA ID / Passport) | Yes | `ID Document` |
| Driver's License | Yes | `Driver's License` |
| Professional Driving Permit (PDP) | No | `Professional Driving Permit (PDP)` |
| Proof of Address | No | `Proof of Address` |

### 2.2 Banking Document (uploaded in Banking step)

| Document | Required | DB `doc_type` value |
|---|---|---|
| Bank Confirmation Letter | No | `Bank Document` |

### 2.3 Vehicle Documents (uploaded per vehicle in Vehicles step)

| Document | Required | DB field |
|---|---|---|
| Vehicle Registration | No | `vehicles.registration_document_url` |
| Insurance Certificate | No | `vehicles.insurance_document_url` |
| Roadworthy Certificate | No | `vehicles.roadworthy_certificate_url` |

---

## 3. Verification Statuses

Uses the existing `verification_status` enum in the database:

| Status | Meaning |
|---|---|
| `pending` | Document uploaded, awaiting admin review |
| `under_review` | Admin has opened/started reviewing the document |
| `documents_requested` | Admin has requested the driver re-upload or provide additional documents |
| `approved` | Document accepted by admin |
| `rejected` | Document rejected by admin (with reason) |

---

## 4. Admin Workflow

### 4.1 Document Queue

The admin sees a list of documents with `verification_status = 'pending'` or `'under_review'`, ordered by `created_at ASC` (oldest first).

**List item displays:**
- Driver name and profile photo
- Document type (`doc_type`)
- Upload date
- Thumbnail preview
- Current status badge

### 4.2 Document Review Screen

When the admin taps a document:

1. **Full-screen document viewer** with zoom/pan
2. **Driver context panel** showing driver name, phone, registration date, and overall verification status
3. **Action buttons:**
   - **Approve** - marks document as accepted
   - **Reject** - opens rejection reason selector + message preview
   - **Request Re-upload** - opens re-upload reason selector + message preview
   - **Flag** - flags document for quality/fraud concerns (writes to `flagged_documents`)

### 4.3 Review Actions

Each action updates the relevant database record and sends a notification to the driver.

#### Approve Document
```
UPDATE driver_docs
SET verification_status = 'approved',
    verified_by = {admin_id},
    verified_at = NOW()
WHERE id = {document_id};
```

#### Reject Document
```
UPDATE driver_docs
SET verification_status = 'rejected',
    verified_by = {admin_id},
    verified_at = NOW(),
    rejection_reason = {reason_text},
    admin_notes = {optional_notes}
WHERE id = {document_id};
```

#### Request Re-upload
```
UPDATE driver_docs
SET verification_status = 'documents_requested',
    admin_notes = {reason_text}
WHERE id = {document_id};
```

---

## 5. Notification Messages

All messages are delivered via **push notification** and stored as **in-app notifications** in the `notifications` table. The driver sees them in the LoadRunner app's notification centre.

### 5.1 Document Approved

**Trigger:** Admin approves a single document.

| Field | Value |
|---|---|
| `notification_type` | `general` |
| **Title** | `Document Approved` |
| **Body** | `Your {doc_type} has been approved. Thank you for submitting valid documentation.` |

**Examples:**
- "Your Driver's License has been approved. Thank you for submitting valid documentation."
- "Your ID Document has been approved. Thank you for submitting valid documentation."

---

### 5.2 All Documents Approved (Driver Fully Verified)

**Trigger:** Admin approves the last outstanding document AND all required documents are now approved, resulting in full driver verification.

| Field | Value |
|---|---|
| `notification_type` | `general` |
| **Title** | `Account Verified` |
| **Body** | `Congratulations! All your documents have been reviewed and approved. Your driver account is now fully verified and you can start bidding on available loads.` |

---

### 5.3 Document Rejected

**Trigger:** Admin rejects a document with a selected reason.

| Field | Value |
|---|---|
| `notification_type` | `general` |
| **Title** | `Document Rejected` |
| **Body** | `Your {doc_type} could not be approved. Reason: {rejection_reason}. Please upload a new {doc_type} from your driver profile.` |

**Rejection Reasons (pre-defined, admin selects one):**

| Code | Display Text | Message Fragment |
|---|---|---|
| `expired` | Expired document | `The document has expired. Please upload a current, valid version.` |
| `blurry` | Poor image quality | `The image is blurry or unreadable. Please take a clear photo with good lighting.` |
| `wrong_doc` | Wrong document type | `The uploaded file does not match the required document type.` |
| `incomplete` | Incomplete / partially visible | `The document is partially cut off or not fully visible. Please upload the complete document.` |
| `mismatch` | Name/details mismatch | `The name or details on this document do not match your profile information.` |
| `damaged` | Damaged document | `The document appears damaged or tampered with. Please upload an undamaged copy.` |
| `not_certified` | Not certified / not colour copy | `This document must be a certified copy or colour scan. Please re-upload accordingly.` |
| `other` | Other (custom reason) | Admin types a custom reason. |

**Example messages:**
- "Your Driver's License could not be approved. Reason: The document has expired. Please upload a current, valid version. Please upload a new Driver's License from your driver profile."
- "Your Proof of Address could not be approved. Reason: The image is blurry or unreadable. Please take a clear photo with good lighting. Please upload a new Proof of Address from your driver profile."

---

### 5.4 Document Re-upload Requested

**Trigger:** Admin requests the driver to re-upload a specific document.

| Field | Value |
|---|---|
| `notification_type` | `general` |
| **Title** | `Document Re-upload Required` |
| **Body** | `We need you to re-upload your {doc_type}. {request_reason} Please open your driver profile and upload a new copy.` |

**Request Reasons (pre-defined, admin selects one):**

| Code | Display Text | Message Fragment |
|---|---|---|
| `better_quality` | Better quality needed | `The current upload is not clear enough for verification.` |
| `newer_version` | Updated version needed | `We require a more recent version of this document (not older than 3 months).` |
| `both_sides` | Both sides required | `Please upload images of both the front and back of the document.` |
| `colour_copy` | Colour copy required | `A colour copy or photo is required. Black-and-white copies are not accepted.` |
| `additional_info` | Additional information needed | `We need additional supporting information to complete verification.` |
| `other` | Other (custom reason) | Admin types a custom reason. |

**Example messages:**
- "We need you to re-upload your ID Document. The current upload is not clear enough for verification. Please open your driver profile and upload a new copy."
- "We need you to re-upload your Proof of Address. We require a more recent version of this document (not older than 3 months). Please open your driver profile and upload a new copy."

---

### 5.5 Missing Required Documents

**Trigger:** Admin reviews a driver's profile and notices required documents are missing. Sent manually.

| Field | Value |
|---|---|
| `notification_type` | `general` |
| **Title** | `Documents Required` |
| **Body** | `To complete your driver verification, please upload the following: {missing_doc_list}. Go to your driver profile to upload these documents.` |

**Example messages:**
- "To complete your driver verification, please upload the following: ID Document, Driver's License. Go to your driver profile to upload these documents."
- "To complete your driver verification, please upload the following: Driver's License. Go to your driver profile to upload these documents."

---

### 5.6 Document Flagged (Fraud / Concern)

**Trigger:** Admin flags a document for suspected fraud or serious concern. This is an internal action; the driver receives a neutral re-upload request.

**Internal record** (written to `flagged_documents`):
```
INSERT INTO flagged_documents (document_id, driver_id, flagged_by_user_id, reason, notes, status)
VALUES ({doc_id}, {driver_id}, {admin_id}, {flag_reason}, {admin_notes}, 'pending');
```

**Driver-facing notification** (same as Re-upload Requested):

| Field | Value |
|---|---|
| `notification_type` | `general` |
| **Title** | `Document Re-upload Required` |
| **Body** | `We were unable to verify your {doc_type}. Please upload a new copy from your driver profile.` |

The driver is NOT informed that the document was flagged. The flag is only visible to admins.

---

### 5.7 Driver Account Suspended

**Trigger:** Admin suspends a driver account due to document fraud or repeated invalid submissions.

| Field | Value |
|---|---|
| `notification_type` | `driver_suspended` |
| **Title** | `Account Suspended` |
| **Body** | `Your driver account has been suspended. Reason: {suspension_reason}. If you believe this is an error, please contact support at support@loadrunner.co.za.` |

---

### 5.8 Driver Account Reactivated

**Trigger:** Admin lifts a suspension after the driver resolves the issue.

| Field | Value |
|---|---|
| `notification_type` | `general` |
| **Title** | `Account Reactivated` |
| **Body** | `Your driver account has been reactivated. You can now continue using LoadRunner and bid on available loads.` |

---

## 6. Bulk Actions

### 6.1 Approve All Documents for a Driver

Admin can approve all pending documents for a driver in one action. This triggers:
1. Individual `Document Approved` notification per document (grouped in notification centre)
2. If all required documents are now approved: `Account Verified` notification

### 6.2 Request All Missing Documents

Admin can send a single notification listing all missing/rejected documents for a driver. Uses the **Missing Required Documents** template (Section 5.5).

---

## 7. Admin Notes

Every review action allows the admin to add optional internal `admin_notes` stored on the `driver_docs` row. These notes are:
- Visible only to admins
- NOT included in driver-facing notifications
- Useful for audit trail and handoff between admin team members

---

## 8. Audit Trail

All document verification actions are logged in the `driver_approval_history` table:

| Field | Value |
|---|---|
| `driver_id` | The driver being reviewed |
| `admin_id` | The admin performing the action |
| `previous_status` | Status before the action |
| `new_status` | Status after the action |
| `reason` | Rejection/request reason (if applicable) |
| `notes` | Admin notes |
| `documents_reviewed` | JSON array of document IDs reviewed in this action |
| `created_at` | Timestamp |

---

## 9. Driver App Behaviour

When a driver receives a document-related notification:

1. Tapping the notification opens the **Driver Profile** screen
2. The affected document tile shows its updated status:
   - **Approved**: Green tick, "Approved" label
   - **Rejected**: Red icon, "Rejected - tap to re-upload" label
   - **Re-upload Requested**: Orange icon, "Re-upload required" label
3. The driver can immediately pick a new image to replace the document
4. On successful re-upload, the document status resets to `pending` and admins are notified via the existing `trg_notify_document_uploaded` trigger

---

## 10. Message Template Summary

| Scenario | Title | Notification Type |
|---|---|---|
| Single document approved | Document Approved | `general` |
| All docs approved / driver verified | Account Verified | `general` |
| Document rejected | Document Rejected | `general` |
| Re-upload requested | Document Re-upload Required | `general` |
| Missing documents reminder | Documents Required | `general` |
| Flagged document (driver-facing) | Document Re-upload Required | `general` |
| Account suspended | Account Suspended | `driver_suspended` |
| Account reactivated | Account Reactivated | `general` |
