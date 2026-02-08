# Red Cocoa Auth Setup Guide

This guide explains how to enable **Apple**, **Google**, and **Phone** sign-in for the Red Cocoa app. All three use Supabase Auth, so you configure them in the [Supabase Dashboard](https://supabase.com/dashboard).

---

## Prerequisites

- Your Supabase project URL and anon key are in `RedCocoa/Info.plist` (already set)
- App bundle ID: `com.redcocoa.app`
- URL scheme: `com.redcocoa.app://auth/callback`

---

## 1. Apple Sign In

### Apple Developer Portal

1. Go to [developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles**
2. **Identifiers** → select your App ID (`com.redcocoa.app`) or create it
3. Enable **Sign in with Apple**
4. Save

### Xcode

- The app already has the Sign in with Apple entitlement in `RedCocoa.entitlements`
- Ensure the capability is enabled in Xcode: **Signing & Capabilities** → **Sign in with Apple**

### Supabase Dashboard

1. Go to **Authentication** → **Providers** → **Apple**
2. Enable **Apple**
3. **Client ID (Service ID)**:
   - For native iOS, use your **App ID (Bundle ID)**: `com.redcocoa.app`
   - Or create a **Services ID** in Apple Developer for the web flow
4. **Secret Key** (optional for native iOS):
   - Create a **Key** in Apple Developer → Keys → Sign in with Apple
   - Download the `.p8` file
   - Note Key ID, Team ID, and Service ID
   - Supabase can use this for the web flow; native iOS often works without it
5. Save

### Notes

- Apple only provides the user’s name on first sign-in; store it immediately
- Test on a real device; Sign in with Apple is limited in Simulator

---

## 2. Google Sign In

### Google Cloud Console

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create or select a project
3. **APIs & Services** → **Credentials** → **Create Credentials** → **OAuth client ID**
4. Application type: **Web application**
5. Name: `Red Cocoa Supabase`
6. **Authorized redirect URIs** → add:
   ```
   https://gvbmhnbnvdexdvjxrhhz.supabase.co/auth/v1/callback
   ```
   (Replace with your Supabase project URL if different.)
7. Create and copy **Client ID** and **Client Secret**

### Supabase Dashboard

1. Go to **Authentication** → **Providers** → **Google**
2. Enable **Google**
3. Paste **Client ID** and **Client Secret** from Google Cloud
4. Save

### URL Configuration (Supabase)

1. Go to **Authentication** → **URL Configuration**
2. **Redirect URLs** → add:
   ```
   com.redcocoa.app://auth/callback
   ```
3. Save

### Flow

- Tapping “Continue with Google” opens Safari
- User signs in → redirects to `com.redcocoa.app://auth/callback`
- App handles the URL via `onOpenURL` and `handleAuthURL`

---

## 3. Phone Sign In (SMS OTP)

Supabase uses **Twilio** for SMS.

### Twilio Setup

1. Sign up at [twilio.com](https://www.twilio.com)
2. Get:
   - **Account SID**
   - **Auth Token**
   - A **Phone Number** (or use Twilio Verify)

### Option A: Twilio Verify (recommended)

1. In Twilio Console → **Verify** → **Services** → create a service
2. Note the **Verification SID**
3. In Supabase: **Authentication** → **Providers** → **Phone**
4. Enable **Phone**
5. **SMS Provider**: **Twilio Verify**
6. Set **Twilio Verify SID** (Verification SID)
7. Add Twilio credentials if needed

### Option B: Twilio Programmable Messaging

1. In Supabase: **Authentication** → **Providers** → **Phone**
2. Enable **Phone**
3. **SMS Provider**: **Twilio** (Programmable Messaging)
4. Enter:
   - **Twilio Account SID**
   - **Twilio Auth Token**
   - **Twilio Phone Number** (e.g. `+1234567890`)

### Usage

- Trial accounts: verified numbers only
- Add verified numbers in Twilio Console for testing
- Production: upgrade Twilio and configure rate limits

---

## Quick Checklist

| Provider | Apple Developer | Google Cloud | Twilio | Supabase Dashboard |
|----------|-----------------|--------------|--------|--------------------|
| **Apple** | App ID + Sign in with Apple | — | — | Enable Apple, set Client ID |
| **Google** | — | OAuth client, redirect URI | — | Enable Google, Client ID/Secret, redirect URL |
| **Phone** | — | — | Account + Verify or Messaging | Enable Phone, Twilio config |

---

## Database Setup (RLS & Profiles)

If you see "new row violates row-level security policy" when saving profiles or photos, run the SQL in `supabase_rls_policies.sql` in the Supabase SQL Editor. It creates the profile trigger, RLS policies, and storage policies for avatars.

## Delete Account (Edge Function)

The app uses a Supabase Edge Function to delete user accounts, including all storage files (photos, videos) and auth data. Deploy it once:

```bash
cd /path/to/red-cocoa
supabase functions deploy delete-user
```

This requires the Supabase CLI and `supabase link` to your project.

## Troubleshooting

- **Apple**: “Invalid configuration” → check bundle ID and entitlement
- **Google**: Nothing happens or redirect fails → check redirect URI in Google and Supabase
- **Phone**: “SMS failed” → check Twilio credentials, trial limits, and verified numbers
- **Delete Account fails**: Ensure `delete-user` Edge Function is deployed (`supabase functions deploy delete-user`)
