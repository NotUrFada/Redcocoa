# Red Cocoa – Requirements & Scope

## 1. Project Overview

**Red Cocoa** is a dating app for iOS only, built with React, Vite, Capacitor, and Supabase.

---

## 2. Technical Requirements

### 2.1 Development
- **Node.js** – To run npm scripts
- **npm** – Package manager
- **macOS + Xcode** – For iOS builds (App Store submission)

### 2.2 Runtime
- **Supabase** – Backend (auth, database, storage, realtime)
- **Environment variables** – `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`
- **Demo mode** – App works without Supabase using mock data

### 2.3 Tech Stack
- React 19 + Vite 7
- React Router 7
- Capacitor 8 (iOS)
- Supabase (PostgreSQL, Auth, Storage, Realtime)

---

## 3. Database Requirements

### 3.1 Migrations (run in order)

| # | File | Purpose |
|---|------|---------|
| 1 | `20250101000000_initial_schema.sql` | Base schema: profiles, preferences, likes, matches, messages, blocked_users, reports, RLS |
| 2 | `20250102000000_passed_and_storage.sql` | passed_users table, avatars storage bucket |
| 3 | `20250103000000_ethnicity_hair.sql` | ethnicity, hair_color on profiles; preferred_ethnicities, preferred_hair_colors on preferences |
| 4 | `20250104000000_humor_culture_features.sql` | humor_preference, tone_vibe, prompt_responses, badges, debunked_lines, not_here_for; filter columns |
| 5 | `20250105000000_realtime_messages.sql` | Adds messages to supabase_realtime (real-time chat) |
| 6 | `20250106000000_matches_insert_policy.sql` | INSERT/UPDATE policies for matches (likes/create matches) |
| 7 | `20250107000000_phone_in_profiles.sql` | phone column for Settings phone number |

### 3.2 Core Tables
- **profiles** – User profiles (name, bio, photos, location, preferences, culture fields, phone)
- **preferences** – Discovery filters (age, distance, ethnicity, hair, humor, tone, etc.)
- **likes** – Who liked whom
- **matches** – Mutual likes
- **messages** – Chat messages per match
- **passed_users** – Profiles passed in discovery
- **blocked_users** – Block list
- **reports** – User reports

### 3.3 Storage
- **avatars** bucket – Profile photos

---

## 4. Authentication Requirements

- **Sign up** – Email + password
- **Sign in** – Email + password
- **Forgot password** – Email reset link
- **Email confirmation** – Redirect to `/auth/callback`
- **Redirect URLs** – Must be configured in Supabase Auth for:
  - `capacitor://localhost/#/auth/callback` (iOS app)
  - `capacitor://localhost/#/reset-password` (iOS app)
  - `http://localhost:5173/#/auth/callback` (dev in browser)
  - `http://localhost:5173/#/reset-password` (dev in browser)

---

## 5. Feature Requirements

### 5.1 Onboarding
- Welcome slides
- Consent (humor preference, tone, respect rule)
- Profile setup (basics, culture prompts, badges, debunked, not here for)
- Permissions (location, notifications)
- Completes when user reaches “Start matching”

### 5.2 Discovery
- Swipeable cards (like, pass, view profile)
- Search by location or interest
- Filters: age, distance, ethnicity, hair, humor, culture, tone, values
- Empty state when no matches
- “You’ve seen them all” when exhausted

### 5.3 Profile View
- Photos, name, age, location, bio
- About me, essentials (ethnicity, hair, intent), prompts, badges, debunked, not here for
- Actions: Pass (X), Send message, Like (heart)
- Report menu (spam, inappropriate, other, block)
- Back button, three-dots menu

### 5.4 Likes
- Grid of people who liked you
- Match status vs “Liked you”

### 5.5 Chats
- List of conversations
- New matches section
- Empty state when no messages
- Filter tabs (All, Unread, Matches, Archive)

### 5.6 Chat (Conversation)
- Message bubbles (sent/received)
- Icebreaker suggestions
- Icebreaker cards bar
- Reaction stickers
- Real-time updates (Supabase Realtime)
- Empty state when no messages
- Header: back, profile pic + name + status, three-dots

### 5.7 Settings
- Humor & vibe
- Edit profile link
- Phone number (profiles.phone)
- Email address
- Dating preferences (age, distance, interests)
- Notifications
- Privacy, legal, blocked users
- Log out

### 5.8 Edit Profile
- Photos
- Bio
- Culture modal (prompts, badges, debunked, not here for)
- Discovery filters (humor, vibe, values)

### 5.9 Legal & Safety
- Privacy Policy
- Terms of Service
- Report/block

---

## 6. UI/UX Requirements

- **Responsive** – Mobile-first (375px target)
- **Safe areas** – Support for notch, home indicator
- **Bottom nav** – Discover, Likes, Chats, Profile (visible on all main screens)
- **Back buttons** – On Chat, Profile, and other detail screens
- **No text cut-off** – Overflow/ellipsis for long text (name, location)

---

## 7. iOS / App Store Requirements

- **Apple Developer Program** – $99/year
- **Bundle Identifier** – e.g. `com.yourcompany.redcocoa`
- **Privacy Policy URL** – Public URL (required)
- **Age Rating** – 17+ (Dating)
- **Screenshots** – Required device sizes
- **Capabilities** – Signing, optional Push Notifications

---

## 8. Deployment Requirements

### 8.1 iOS (only)
- Build: `npm run ios`
- Configure in Xcode (Team, Bundle ID, Signing)
- Archive and upload to App Store Connect
- Submit for review

---

## 9. Optional / Future Considerations

- **Custom SMTP** – For higher email limits (Supabase default: 2/hour)
- **Push Notifications** – For new matches/messages
- **Analytics** – Usage tracking
- **Moderation** – Content moderation for photos/messages

---

## 10. Summary Checklist

- [ ] Supabase project created
- [ ] All 7 migrations run in SQL Editor
- [ ] `.env` with `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`
- [ ] Redirect URLs configured in Supabase Auth
- [ ] Privacy Policy hosted at public URL
- [ ] App tested locally (signup, discovery, likes, chat)
- [ ] iOS build from Xcode (Team, Bundle ID, Signing)
- [ ] App Store Connect app created
- [ ] Screenshots and metadata added
- [ ] Submitted for review
