# In-App Voice & Video Calls Setup

Red Cocoa uses **Agora** for in-app voice and video calling (no FaceTime or phone required).

## 1. Agora Account & App ID

1. Sign up at [console.agora.io](https://console.agora.io)
2. Create a project and copy the **App ID**
3. In Xcode, open `Info.plist` and set `AGORA_APP_ID` to your App ID (e.g. `"a1b2c3d4e5f6..."`)

## 2. Token (for production)

For testing, you can use a temporary token from [Agora Token Generator](https://agora-token-generator-demo.vercel.app/). For production, run a token server. See [Agora Token Server](https://docs.agora.io/en/video-calling/develop/authentication-workflow).

## 3. Database Migration

Run the call invites migration:

```bash
# From project root
supabase db push
```

Or manually run `supabase/migrations/20250112000000_call_invites.sql` in the Supabase SQL Editor.

## 4. Testing

1. Open a chat with a match
2. Tap the **phone** icon for voice call or **video** icon for video call
3. The other user (in the same chat) will see an incoming call overlay and can answer
4. Both users must have the app open in the chat for calls to work (no push notifications yet)

## Flow

- **Outgoing**: Tap call → create invite in DB → join Agora channel → show call UI
- **Incoming**: Chat polls for ringing invites → show overlay → Answer/Decline
- **Answer**: Join same channel → both users see/hear each other
