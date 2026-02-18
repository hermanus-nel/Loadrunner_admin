// lib/features/messages/presentation/routes/messages_routes.dart
//
// Route Configuration Guide for Messages Feature
// Add these routes to your app_router.dart
//

/*
ROUTE CONFIGURATION FOR MESSAGES FEATURE
========================================

Add these imports at the top of app_router.dart:
-----------------------------------------------

import '../features/messages/presentation/screens/messages_screen.dart';
import '../features/messages/presentation/screens/conversation_screen.dart';
import '../features/messages/presentation/screens/compose_message_screen.dart';
import '../features/messages/presentation/screens/broadcast_screen.dart';
import '../features/messages/domain/entities/message_entity.dart';
import '../features/messages/domain/entities/message_template_entity.dart';


Inside ShellRoute (bottom navigation routes):
--------------------------------------------

GoRoute(
  path: '/messages',
  name: 'messages',
  pageBuilder: (context, state) => const NoTransitionPage(
    child: MessagesScreen(),
  ),
),


Root level routes (outside ShellRoute, for full-screen pages):
-------------------------------------------------------------

// Conversation detail screen
GoRoute(
  path: '/messages/conversation/:userId',
  name: 'conversation',
  builder: (context, state) {
    final userId = state.pathParameters['userId']!;
    return ConversationScreen(userId: userId);
  },
),

// Compose new message screen
GoRoute(
  path: '/messages/compose',
  name: 'compose-message',
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>?;
    return ComposeMessageScreen(
      initialTemplate: extra?['template'] as MessageTemplateEntity?,
      initialRecipient: extra?['recipient'] as MessageUserInfo?,
    );
  },
),

// Broadcast screen
GoRoute(
  path: '/messages/broadcast',
  name: 'broadcast',
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>?;
    return BroadcastScreen(
      initialTemplate: extra?['template'] as MessageTemplateEntity?,
    );
  },
),


NAVIGATION EXAMPLES
==================

// Navigate to messages tab
context.go('/messages');

// Navigate to a specific conversation
context.push('/messages/conversation/$userId');

// Navigate to compose message
context.push('/messages/compose');

// Navigate to compose message with template
context.push('/messages/compose', extra: {'template': template});

// Navigate to compose message with pre-selected recipient
context.push('/messages/compose', extra: {'recipient': userInfo});

// Navigate to broadcast screen
context.push('/messages/broadcast');

// Navigate to broadcast screen with template
context.push('/messages/broadcast', extra: {'template': template});


BOTTOM NAVIGATION UPDATE
=======================

Update your main navigation items to include Messages:

NavigationDestination(
  icon: Badge(
    isLabelVisible: unreadCount > 0,
    label: Text('$unreadCount'),
    child: const Icon(Icons.message_outlined),
  ),
  selectedIcon: Badge(
    isLabelVisible: unreadCount > 0,
    label: Text('$unreadCount'),
    child: const Icon(Icons.message),
  ),
  label: 'Messages',
),

To get unread count, use the provider:

final unreadCountAsync = ref.watch(unreadCountProvider);
final unreadCount = unreadCountAsync.valueOrNull ?? 0;


DATABASE REQUIREMENTS
====================

Ensure these tables exist in your Supabase database:

1. admin_messages - Main messaging table (should already exist per schema)
2. message_templates - For storing reusable templates

Optional: Create message_templates table if not exists:

CREATE TABLE IF NOT EXISTS message_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  subject TEXT,
  body TEXT NOT NULL,
  category TEXT DEFAULT 'general',
  is_active BOOLEAN DEFAULT TRUE,
  usage_count INTEGER DEFAULT 0,
  created_by UUID REFERENCES admin_users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

CREATE INDEX idx_message_templates_category ON message_templates(category);
CREATE INDEX idx_message_templates_is_active ON message_templates(is_active);

-- Function to increment usage count
CREATE OR REPLACE FUNCTION increment_template_usage(template_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE message_templates
  SET usage_count = usage_count + 1,
      updated_at = NOW()
  WHERE id = template_id;
END;
$$ LANGUAGE plpgsql;

*/
