# Messages

Admin messaging system with direct messages, broadcasts, conversation threading, message templates, and push notification support.

## Architecture

- **Layers**: domain (entities, repository interface) / data (repository impl) / presentation (providers, screens, widgets, routes)
- **State Management**: 5 separate StateNotifiers — `ConversationsNotifier`, `ConversationMessagesNotifier`, `BroadcastsNotifier`, `TemplatesNotifier`, `UserSearchNotifier`
- **Loading Strategy**: Conversations auto-mark as read on open; broadcasts support date/search filtering

## Entities

### MessageEntity
- Fields: `id`, `senderId?`, `recipientId?`, `messageType` (MessageType), `subject?`, `body`, `sentAt`, `readAt?`, `pushNotificationSent`, `metadata?`, `recipientRole?`, `sender?`, `recipient?` (MessageUserInfo), `recipientCount?`
- `MessageType` enum: `direct`, `broadcast`, `system`
- Helpers: `isRead`, `isBroadcast`, `isFromAdmin`, `previewText` (100-char truncation)

### BroadcastAudience (enum, 5 values)
- `all`, `drivers`, `shippers`, `verifiedDrivers`, `unverifiedDrivers`

### ConversationEntity
- Fields: `id`, `participant` (MessageUserInfo), `lastMessage?`, `unreadCount`, `lastMessageAt`, `totalMessages`
- Helpers: `hasUnread`, `previewText`, `lastSubject`

### ConversationStats
- Fields: `totalConversations`, `totalUnread`, `totalBroadcastsSent`, `totalDirectMessagesSent`, `activeConversationsToday`

### MessageTemplateEntity
- Fields: `id`, `name`, `subject?`, `body`, `category` (TemplateCategory), `isActive`, `usageCount`, `createdAt`, `updatedAt?`, `createdBy?`
- `TemplateCategory` enum: `general`, `documentRequest`, `verification`, `payment`, `warning`, `support`
- Helpers: `previewText` (80 chars), `hasPlaceholders`, `placeholders` (extracts `{{key}}` names), `fillTemplate(values)`

### MessageFilters, MessagesPagination, MessageUserInfo

## Repositories

### MessagesRepository (abstract)
- **Conversations**: `fetchConversations(pagination?, searchQuery?)`, `fetchMessages(userId, pagination?)`
- **Broadcasts**: `fetchBroadcasts(pagination?, filters?)`
- **Sending**: `sendMessage(recipientId, body, subject?, sendPushNotification?)`, `sendBroadcast(audience, body, subject?, sendPushNotification?, specificUserIds?)`
- **Read tracking**: `markAsRead(messageIds)`, `markConversationAsRead(userId)`
- **Templates**: `fetchTemplates(category?, activeOnly?)`, `createTemplate(...)`, `updateTemplate(...)`, `deleteTemplate(templateId)`, `incrementTemplateUsage(templateId)`
- **Search**: `searchUsers(query, role?, limit?)`, `getUnreadCount()`, `getStats()`

### MessagesRepositoryImpl
- **Tables**: `admin_messages` (main), `message_templates`, `users`, `admin_audit_logs`
- **Broadcast flow**: Query users by audience criteria → create parent record (recipient_id=null) → batch insert individual messages (100 per batch)
- **Audience queries**: all=all users, drivers=role='Driver', shippers=role='Shipper', verifiedDrivers=driver_verified_at IS NOT NULL, unverifiedDrivers=driver_verified_at IS NULL
- **Template usage**: RPC call `increment_template_usage(template_id)`
- **Audit**: Actions logged: `message_sent`, `broadcast_sent`

## Providers

- `messagesRepositoryProvider` — repository instance
- `conversationsNotifierProvider` — conversations list with search
- `conversationMessagesNotifierProvider` — messages for single conversation; separates `isSending` from `isLoading`
- `broadcastsNotifierProvider` — broadcasts list with filters
- `templatesNotifierProvider` — template CRUD with category filter; `filteredTemplates` computed client-side
- `userSearchNotifierProvider` — user search (min 2 chars)
- `unreadCountProvider`, `messageStatsProvider` — FutureProviders

## Screens & Widgets

- **MessagesScreen**: 3 tabs (Inbox, Broadcasts, Templates); unread badge on Inbox tab; AppBar add button for new message/broadcast/template
- **ConversationScreen**: Chat-style UI with reverse ListView, date separators, typing indicator; message bubbles (admin=right/primary, user=left/gray); push notification toggle; template selector; long-press to copy
- **ComposeMessageScreen**: Recipient card with search, subject/body fields, template selector bottom sheet, push notification toggle, preview section
- **BroadcastScreen**: Audience radio buttons with descriptions, subject/body, push toggle, preview mode, confirmation checklist (3 items), final confirmation dialog
- **ConversationTile**: Avatar with unread indicator, name, role badge, timestamp, message preview, unread count
- **MessageBubble**: Subject + body, time, read status (single/double check), push icon; `SystemMessageBubble`, `TypingIndicator`
- **UserSelector**: Search field (min 2 chars), role filter chips, result list; `MultiUserSelector` variant
- **BroadcastTile**: Campaign icon, subject, audience, preview, recipient count
- **TemplateSelector**: Bottom sheet with category filter chips and template list
- **TemplateTile**: Category icon, name, badge, subject, preview, placeholder count, usage count

## Business Rules

- **Auto-mark read**: Conversations marked as read when opened (`markConversationAsRead()`)
- **Broadcast batching**: Individual messages inserted in batches of 100
- **Template placeholders**: `{{key}}` format; extracted via regex `\{\{(\w+)\}\}`
- **User search**: Min 2 characters; searches first_name, last_name, phone_number, email (case-insensitive ilike)
- **Push notification**: Optional per-message toggle; tracked via `pushNotificationSent` field
- **Message preview**: Truncated to 100 chars (messages) or 80 chars (templates)
- **Read status icons**: Single check = sent, double check = read (primary color), bell = push sent
- **Default pagination**: 20 items per page
- **Audit logging**: Non-critical — failures don't block message operations
