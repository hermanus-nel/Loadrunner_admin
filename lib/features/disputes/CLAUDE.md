# Disputes

Full dispute resolution system with lifecycle management, evidence tracking, timeline events, admin notes, and resolution workflows.

## Architecture

- **Layers**: domain (entities, repository interface) / data (repository impl) / presentation (providers, screens, widgets)
- **State Management**: `DisputesListNotifier` (list + filters + pagination) and `DisputeDetailNotifier` (single dispute with evidence + timeline)
- **Loading Strategy**: List fetches disputes and stats together; detail fetches dispute, evidence, and timeline

## Entities

### DisputeEntity
- Fields: `id`, `title`, `description`, `raisedById`, `raisedAgainstId`, `freightPostId?`, `status` (DisputeStatus), `type` (DisputeType), `priority` (DisputePriority), `resolution?` (ResolutionType), `resolutionNotes?`, `refundAmount?`, `adminAssignedId?`, `resolvedById?`, `createdAt`, `updatedAt`, `resolvedAt?`
- Related: `raisedBy?`, `raisedAgainst?`, `adminAssigned?` (DisputeUserInfo), `shipment?` (DisputeShipmentInfo), `evidenceCount`
- Helpers: `isActive`, `ageInDays`, `resolutionTimeInDays`

### DisputeStatus (enum)
- `open` → `investigating` → `awaitingEvidence` → `resolved` → `closed`
- Alternate: any → `escalated` (sets priority to urgent)
- `isActive`: true for open, investigating, awaitingEvidence, escalated

### DisputeType (enum, 7 values)
- `latePick`, `damagedGoods`, `nonDelivery`, `paymentDispute`, `serviceQuality`, `fraudulent`, `other`

### DisputePriority (enum)
- `low`, `medium`, `high`, `urgent` — sort order: urgent(0) > high(1) > medium(2) > low(3)

### ResolutionType (enum, 6 values)
- `favorShipper`, `favorDriver`, `splitDecision`, `mediated`, `noAction`, `escalated`

### EvidenceEntity
- Fields: `id`, `disputeId`, `submittedById`, `evidenceType` (EvidenceType), `fileUrl?`, `description?`, `metadata?`, `createdAt`, `submittedBy?`
- Helpers: `isImage`, `hasFile`, `fileExtension`, `isImageFile`, `isDocumentFile`, `gpsCoordinates`, `capturedAt`

### EvidenceType (enum, 8 values)
- `photo`, `document`, `deliveryProof`, `damagePhoto`, `receipt`, `gpsData`, `communication`, `other`
- Image types: photo, deliveryProof, damagePhoto

### DisputeTimelineEvent
- Fields: `id`, `disputeId`, `eventType`, `description?`, `performedById?`, `performedBy?`, `metadata?`, `createdAt`
- Event types: created, assigned, status_changed, evidence_added, escalated, resolved, closed, comment_added, priority_changed

### DisputeNote, DisputeFilters, DisputesPagination, DisputeStats

## Repositories

### DisputesRepository (abstract, 16 methods)
- **CRUD**: `fetchDisputes`, `fetchDisputeDetail`
- **Actions**: `resolveDispute`, `escalateDispute`, `updateDisputeStatus`, `updateDisputePriority`, `assignDispute`, `assignToSelf`
- **Evidence**: `addEvidence`, `requestEvidence`, `fetchEvidence`
- **Notes**: `addNote`
- **Timeline**: `fetchTimeline`
- **Stats**: `getStats`, `getDisputesByUser`, `getDisputesByShipment`

### DisputesRepositoryImpl
- **Tables**: `disputes` (with user joins), `dispute_evidence`, `admin_audit_logs` (timeline), `admin_messages` (evidence requests), `freight_posts`
- **List ordering**: priority ASC, created_at DESC (urgent disputes first)
- **All mutations**: Log to `admin_audit_logs` with `target_type='dispute'`

## Providers

- `disputesRepositoryProvider` — repository instance
- `disputesListNotifierProvider` — list state with filters, pagination, stats
- `disputeDetailNotifierProvider` — detail state with evidence and timeline
- **Detail notifier methods**: `fetchDisputeDetail`, `resolveDispute`, `escalateDispute`, `updateStatus`, `updatePriority`, `assignToSelf`, `addEvidence`, `requestEvidence`, `addNote`, `clear`
- FutureProviders: `disputeStatsProvider` (family), `defaultDisputeStatsProvider` (last 30 days), `disputesByUserProvider`, `disputesByShipmentProvider`

## Screens & Widgets

- **DisputesListScreen**: Stats bar (open, investigating, resolved, urgent), search, collapsible filter panel (status/type/priority chips, date range), quick filters ("Assigned to me", "Urgent Only", "Open Only"), infinite scroll list
- **DisputeDetailScreen**: 3 tabs — Details (status/priority badges, parties, shipment, assignment, resolution, dates), Evidence (gallery + add button), Timeline (chronological events)
- **Action bar**: Status change, Escalate, Resolve buttons (for active disputes)
- **DisputeTile**: Priority indicator bar, title, description preview, type/priority badges, evidence count, party avatars
- **DisputeStatusBadge**: Color-coded — open=orange, investigating=blue, awaitingEvidence=purple, resolved=green, escalated=red, closed=grey
- **DisputePriorityBadge**: low=grey, medium=blue, high=orange, urgent=red; `UrgentIndicator` with pulsing animation
- **DisputeTimeline**: Vertical timeline with colored event icons and connecting lines
- **EvidenceGallery / EvidenceViewerScreen**: Full-screen viewer with swipe navigation, interactive zoom (0.5x-4x), info overlay
- **ResolutionDialog**: Resolution type radio selection, optional refund (favorShipper/splitDecision), notes (min 10 chars), irreversibility warning
- **RequestEvidenceDialog**: Select user (raised_by or raised_against), message field

## Business Rules

- **Status workflow**: open → investigating → awaitingEvidence → resolved → closed; any → escalated
- **Escalation**: Sets priority to urgent automatically
- **Refund eligible**: Only `favorShipper` and `splitDecision` resolutions
- **Resolution validation**: Notes required (min 10 chars); refund amount > 0 if refund checked
- **Age warning**: Red color if dispute open > 7 days
- **Default pagination**: 20 items per page
- **Sort order**: Priority ascending (urgent first), then created_at descending
- **Statistics**: `resolutionRate = (resolved / total) * 100`; `averageResolutionDays` from resolved disputes
- **All mutations audited**: Every status change, assignment, escalation, and resolution logged to `admin_audit_logs`
