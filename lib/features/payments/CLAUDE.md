# Payments

Payment transaction management with listing, detail views, refund processing, failed payment retry, and commission tracking via Paystack gateway.

## Architecture

- **Layers**: domain (entities, repository interface) / data (models, repository impl) / presentation (providers, screens, widgets, routes)
- **State Management**: `PaymentsListNotifier` (list + filters + pagination) and `PaymentDetailNotifier` (single payment + actions)
- **Loading Strategy**: Paginated list with filters; detail view with full related data

## Entities

### PaymentEntity
- **Core**: `id`, `amount`, `status` (PaymentStatus), `paymentMethod?` ('card'/'bank'/'ussd'/'qr'), `paymentChannel?`, `currency` (default 'ZAR'), `createdAt`, `paidAt?`
- **Relationships**: `freightPostId?`, `bidId?`, `shipperId?`
- **Commission**: `bidAmount`, `shipperCommission`, `driverCommission`, `totalCommission`
- **Paystack**: `transactionId?`, `paystackReference?`
- **Error**: `failureReason?`
- **Related**: `payer?`, `payee?` (PaymentUserInfo), `shipment?` (PaymentShipmentInfo), `refund?` (PaymentRefundInfo)
- **Metadata**: `metadata?` — stores `retry_count`, `original_transaction_id`, `retried_at`
- Helpers: `canRefund` (success && no refund), `canRetry` (failed), `formattedAmount`, `netAmount` (bidAmount - driverCommission)

### PaymentStatus (enum)
- `pending`, `success`, `failed`, `refunded`, `cancelled`
- Parsing: handles 'completed' → success, 'canceled' → cancelled

### PaymentFilters
- Fields: `status?`, `startDate?`, `endDate?`, `minAmount?`, `maxAmount?`, `searchQuery?`
- Search targets: transaction ID, paystack reference, user name

### PaymentsPagination, PaymentUserInfo, PaymentShipmentInfo, PaymentRefundInfo

## Repositories

### PaymentsRepository (abstract)
- `fetchTransactions(filters?, pagination?)` → `PaymentsResult`
- `fetchTransactionDetail(paymentId)` → `PaymentEntity`
- `processRefund(paymentId, reason, amount?)` → `RefundResult`
- `retryPayment(paymentId)` → `RetryResult`
- `getPaymentStats(startDate?, endDate?)` → `PaymentStats`

### PaymentsRepositoryImpl
- **Tables**: `payments` (with joins to `users`, `freight_posts`, `bids`, `payment_refunds`), `escrow_holdings`, `admin_audit_logs`
- **Search**: Pre-fetches user IDs by name, then OR clause on transaction_id/paystack_reference/shipper_id
- **Refund flow**: Creates `payment_refunds` record with 5% cancellation fee, updates payment status to 'refunded'
- **Retry flow**: Generates new transaction ID (`RETRY_{timestamp}`), updates status to 'pending', increments `metadata.retry_count`
- **Stats**: Aggregates by status; queries `payment_refunds` for refunded amount
- **Audit**: Actions `process_refund` and `retry_payment` logged to `admin_audit_logs`

## Providers

- `paymentsRepositoryProvider` — repository instance
- `paymentsListNotifierProvider` — `StateNotifier<PaymentsListState>` (list, filters, pagination, isLoading, isLoadingMore)
- `paymentDetailNotifierProvider` — `StateNotifier<PaymentDetailState>` (payment, isLoading, isProcessingAction, actionMessage)
- `paymentStatsProvider` — `FutureProvider.family<PaymentStats, ({DateTime? startDate, DateTime? endDate})>`
- `defaultPaymentStatsProvider` — last 30 days stats

### PaymentStats
- Fields: `totalRevenue`, `totalCommissions`, `totalTransactions`, `successfulTransactions`, `failedTransactions`, `pendingTransactions`, `refundedTransactions`, `refundedAmount`
- Computed: `successRate` = (successful / total) * 100

## Screens & Widgets

- **PaymentsScreen**: Delegates to `TransactionsListScreen`
- **TransactionsListScreen**: Search bar, animated filter panel (status chips, date pickers with quick filters, amount range), stats summary, infinite scroll list with pull-to-refresh
- **TransactionDetailScreen**: Amount card with status badge, transaction details, commission breakdown, payer/payee info, shipment, failure/refund sections; action bar with "Process Refund" or "Retry Payment"
- **PaymentListTile**: Amount (color-coded), status badge, transaction ID (monospace), payer name, payment method icon, date, commission; conditional failure/refund info boxes
- **PaymentStatusBadge**: success=green, pending=orange, failed=red, refunded=blue, cancelled=grey
- **RefundDialog**: Full/partial toggle, partial amount input, reason (required, min 10 chars), refund breakdown (amount, 5% fee, customer receives), irreversibility warning
- **RetryDialog**: Payment info card, failure reason, "What happens" info box, retry count warning if retried before

## Business Rules

- **Cancellation fee**: 5% flat on refund amount; net refund = amount - fee
- **Refund eligibility**: Only `success` status with no existing refund
- **Retry eligibility**: Only `failed` status
- **Retry tracking**: `metadata.retry_count` incremented; `metadata.original_transaction_id` stored on first retry
- **Currency**: ZAR (South African Rand), formatted as `R 1000.00` via `NumberFormat.currency`
- **Date formatting**: `dd MMM yyyy, HH:mm`
- **Date filter**: Inclusive start, exclusive end (adds 1 day)
- **Default stats range**: Last 30 days
- **Default pagination**: 20 per page
- **Scroll load trigger**: 200px from bottom
- **Audit logging**: Non-blocking — failures don't prevent operations
- **Status display names**: pending="Pending", success="Completed", failed="Failed", refunded="Refunded", cancelled="Cancelled"
