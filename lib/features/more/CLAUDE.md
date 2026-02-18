# More

Navigation hub screen providing access to analytics, management tools, settings, and account actions. Minimal feature with presentation layer only.

## Architecture

- **Layers**: Only presentation/screens — domain and data layers are empty (reserved for future)
- **State Management**: `ConsumerWidget` — watches `documentQueueCountProvider` from the users feature for the live Document Queue badge
- **Type**: `ConsumerWidget`

## Entities

None implemented.

## Repositories

None implemented.

## Providers

None owned by this feature. Watches:
- `documentQueueCountProvider` (from `users` feature) — live count of pending/under_review documents for badge display

## Screens & Widgets

### MoreScreen
- **Route**: `/more` (bottom navigation tab, `NoTransitionPage`)
- **AppBar**: "More" title with home button (navigates to `/`)
- **4 sections** in a ListView:

**Analytics**:
- Activity Metrics → `/analytics` (tab 0)
- Financial Metrics → `/analytics` (tab 1)
- Growth Metrics → `/analytics` (tab 2)

**Management**:
- Document Queue → `/document-queue` (live orange badge from `documentQueueCountProvider`, hidden when 0)
- Disputes (TODO — hardcoded badge "3")
- Bank Verifications (TODO — hardcoded badge "5")
- SMS Usage → `/sms-usage` (implemented)
- Audit Logs (TODO)

**Settings**:
- My Profile (TODO)
- Notifications → `/notifications/preferences` (implemented)
- Appearance (TODO)

**Account**:
- Security (TODO)
- Sign Out — destructive style (red), shows confirmation dialog (logout logic TODO)

### Helper Widgets (private)
- `_buildSectionHeader()` — section title with theme-aware colors
- `_buildMenuCard()` — card wrapping menu items
- `_buildMenuItem()` — ListTile with icon container, title, subtitle, optional badge, optional destructive styling
- `_buildDivider()` — indented divider aligned with subtitle text
- `_showLogoutDialog()` — confirmation dialog (sign-out action not yet implemented)

## Business Rules

- **Analytics navigation**: Passes `tab` parameter via `extra` map to `AnalyticsScreen`
- **Document Queue badge**: Live count from `documentQueueCountProvider` (Supabase query); badge hidden when count is 0; orange colour
- **Badge values**: Disputes ("3") and Bank Verifications ("5") are still hardcoded — should be dynamic from providers
- **Theme awareness**: Adapts colors for light/dark mode via `Theme.of(context).brightness`
- **Destructive actions**: Sign Out uses red styling with confirmation dialog
- **Implemented routes**: Analytics (3 tabs), Document Queue, SMS Usage, Notifications Preferences, Home; all others are TODO stubs
