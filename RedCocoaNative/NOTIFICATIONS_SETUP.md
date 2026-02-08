# Push Notifications Setup (Lock Screen)

Red Cocoa is configured to request notification permission and register for push. To have notifications appear on the lock screen when you receive messages, complete these steps.

## 1. iOS App (Done)

- Permission request on app launch
- Device token saved to Supabase when user is signed in
- Push Notifications capability in entitlements

## 2. Database

Run the migration to create `user_device_tokens`:

```bash
npx supabase db push
```

Or run `supabase/migrations/20250114000000_user_device_tokens.sql` in the Supabase SQL Editor.

## 3. Database Webhook

1. Go to [Supabase Dashboard](https://supabase.com/dashboard) → your project → **Database** → **Webhooks**
2. Click **Create a new hook**
3. **Name:** `push-on-message`
4. **Table:** `messages`
5. **Events:** tick **Insert**
6. **Type:** Supabase Edge Functions
7. **Function:** `push-message`
8. Click **Create webhook**

## 4. Edge Function

Deploy the function:

```bash
supabase functions deploy push-message
```

## 5. APNs Credentials (Apple Developer)

To actually send push notifications, you need APNs credentials:

1. Go to [Apple Developer](https://developer.apple.com) → **Certificates, Identifiers & Profiles** → **Keys**
2. Create a new Key with **Apple Push Notifications service (APNs)** enabled
3. Download the `.p8` file (you can only download once)
4. Note the **Key ID** and your **Team ID**

Set the secrets in Supabase:

```bash
supabase secrets set APNS_KEY_ID=your_key_id
supabase secrets set APNS_TEAM_ID=your_team_id
supabase secrets set APNS_KEY="$(cat AuthKey_XXXXX.p8 | base64)"
supabase secrets set APNS_BUNDLE_ID=com.redcocoa.app
```

The Edge Function currently logs the notification payload. To complete the APNs send, you’ll need to add JWT signing and an HTTP/2 request to `api.sandbox.push.apple.com` (dev) or `api.push.apple.com` (prod). Libraries like `apns2` (Node) can be used from a separate service if needed.

## 6. Alternative: OneSignal / Firebase

For a simpler setup, you can use a push service:

1. Register with [OneSignal](https://onesignal.com) or [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
2. Integrate their SDK in the app and use their device token/topic system
3. Call their REST API from the Edge Function instead of APNs directly
