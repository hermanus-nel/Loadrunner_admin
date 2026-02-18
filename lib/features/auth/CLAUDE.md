# Auth

OTP-based phone authentication with admin role verification. Only users with `role = 'Admin'` can access the app.

## Architecture

- **Layers**: data/services (AuthService) / presentation (providers, screens) — simplified architecture, no domain layer
- **State Management**: `AuthNotifier` (StateNotifier) with `AppAuthState`; listens to `SessionService.authStateChanges` stream
- **Dependencies**: `SessionService` (token management), `BulkSmsService` (OTP delivery)

## Entities

### AppAuthState
- Fields: `isInitialized`, `isAuthenticated`, `isLoading`, `userId?`, `phoneNumber?`, `userRole?`, `error?`, `isOtpSent`, `resendCountdown`
- Helpers: `isAdmin` (`userRole == 'Admin'`), `hasError`, `initials`

## Repositories

No formal repository — business logic lives in `AuthService`.

### AuthService
- `sendOTP(phoneNumber)` → `{success, message}` — sends 6-digit OTP via BulkSMS
- `verifyOTP(phoneNumber, otp)` → `{success, userId, userRole, isNewUser}` — verifies OTP, creates session, **rejects non-Admin users**
- `signOut()` — clears session
- Getters: `isAuthenticated`, `authStateChanges` (Stream), `userId`, `userPhone`, `getUserRole()`

### SessionService (core service)
- Manages JWT tokens (access + refresh) in FlutterSecureStorage
- Edge Function calls for session creation
- Background refresh every 25 minutes; proactive refresh if <15 min until expiry
- Max 3 consecutive refresh failures before auto sign-out

### BulkSmsService (core service)
- BulkSMS API (`api.bulksms.com/v1/messages`) with Basic Auth
- 6-digit OTP generation, stored with 5-minute expiry in FlutterSecureStorage
- Message format: `"{otp}: Your LoadRunner Admin verification code is: {otp}. Valid for 5 minutes."`

## Providers

- `authServiceProvider` — `Provider<AuthService>`
- `authNotifierProvider` — `StateNotifierProvider<AuthNotifier, AppAuthState>`
- **Convenience providers**: `isUserAuthenticatedProvider`, `isAuthInitializedProvider`, `isAuthLoadingProvider`, `authUserIdProvider`, `authUserPhoneProvider`, `authUserRoleProvider`, `authErrorProvider`, `isAdminProvider`, `isOtpSentProvider`

### AuthNotifier
- Auto-calls `_initialize()` on construction (checks stored session, validates admin role)
- `sendOtp(phoneNumber)` — sends OTP, sets `isOtpSent: true`
- `verifyOtp(otp)` — verifies, sets `isAuthenticated: true` on success
- `signOut()`, `resetOtpState()`, `clearError()`, `refreshUserData()`

## Screens & Widgets

### SignupScreen (single screen)
- **Mode 1 (Phone Entry)**: Country code picker (default ZA/+27, favorites: +27, +1, +44), phone number field
- **Mode 2 (OTP Verification)**: 6-digit input (numeric, center-aligned, 24pt), resend with 60-second countdown, "Change phone number" button
- Admin notice: "Only users with Admin role can access this app."
- On success: navigates to `AppRoutes.dashboard`

## Business Rules

- **Admin gate**: After OTP verification, if `userRole != 'Admin'`, immediately sign out with "Access denied. Admin privileges required."
- **OTP validity**: 5 minutes from generation
- **OTP length**: 6 digits (100000-999999)
- **Resend cooldown**: 60 seconds
- **Phone validation**: 7-15 digits after cleaning non-digit chars
- **Token lifecycle**: Access ~1hr, refresh ~7 days; background refresh every 25 min; refresh if <15 min left
- **Max refresh retries**: 3 consecutive failures → auto sign-out
- **Route redirect**: Not authenticated → `/login`; authenticated on `/login` → `/` (dashboard)
- **Session storage keys**: `admin_access_token`, `admin_refresh_token`, `admin_user_id`, `admin_user_phone`
