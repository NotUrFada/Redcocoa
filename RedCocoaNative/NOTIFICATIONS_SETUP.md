# Push Notifications Setup (Lock Screen)

Red Cocoa is configured to request notification permission and register for push. Notifications can appear when the app is in the foreground, in the background, or closed—for both **messages** and **incoming calls**.

## 1. iOS App (Done)

- Permission request on app launch
- Device token saved to Supabase when user is signed in
- Push Notifications capability in entitlements
- Incoming call notifications with Accept/Decline (local when in app, remote when app is backgrounded/closed)

## 2. Database

Run the migration to create `user_device_tokens`:

```bash
npx supabase db push
```

Or run `supabase/migrations/20250114000000_user_device_tokens.sql` in the Supabase SQL Editor.

## 3. Database Webhooks

Create **two** webhooks so the callee gets notified on and off the app.

### Messages

1. Go to [Supabase Dashboard](https://supabase.com/dashboard) → your project → **Database** → **Webhooks**
2. Click **Create a new hook**
3. **Name:** `push-on-message`
4. **Table:** `messages`
5. **Events:** tick **Insert**
6. **Type:** Supabase Edge Functions
7. **Function:** `push-message`
8. Click **Create webhook**

### Incoming calls (notify on and off the app)

1. Create another webhook
2. **Name:** `push-on-call-invite`
3. **Table:** `call_invites`
4. **Events:** tick **Insert**
5. **Type:** Supabase Edge Functions
6. **Function:** `push-call-invite`
7. Click **Create webhook**

## 4. Edge Functions

Deploy both functions:

```bash
supabase functions deploy push-message
supabase functions deploy push-call-invite
```

## 5. APNs Credentials (Apple Developer)

To actually send push notifications (messages and calls), you need APNs credentials:

1. Go to [Apple Developer](https://developer.apple.com) → **Certificates, Identifiers & Profiles** → **Keys**
2. Create a new Key with **Apple Push Notifications service (APNs)** enabled
3. Download the `.p8` file (you can only download once)
4. Note the **Key ID** and your **Team ID**

Set the secrets in Supabase (shared by both push-message and push-call-invite):

```bash
supabase secrets set APNS_KEY_ID=your_key_id
supabase secrets set APNS_TEAM_ID=your_team_id
supabase secrets set APNS_KEY="$(cat AuthKey_XXXXX.p8 | base64)"
supabase secrets set APNS_BUNDLE_ID=com.redcocoa.app
```

For production builds use:

```bash
supabase secrets set APNS_PRODUCTION=true
```

The **push-call-invite** function sends a real push with JWT to APNs when a call is created, so the callee gets a notification with Accept/Decline even when the app is in the background or closed. If delivery fails (e.g. APNs requires HTTP/2 in some environments), use a push proxy or OneSignal/Firebase that forwards to APNs.

## 6. Alternative: OneSignal / Firebase

For a simpler setup, you can use a push service:

1. Register with [OneSignal](https://onesignal.com) or [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
2. Integrate their SDK in the app and use their device token/topic system
3. Call their REST API from the Edge Function instead of APNs directly
