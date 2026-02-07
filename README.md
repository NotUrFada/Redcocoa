# Red Cocoa

A dating app built for iOS App Store submission. Built with React, Vite, Capacitor, and Supabase.

## Features

- **Discover** – Browse profiles, pass or like, empty state
- **Profile** – Full profile view with report/block safety features
- **Likes** – Grid of people who liked you
- **Chats** – Message list with new matches
- **Chat** – Conversation view
- **Settings** – Account, preferences, notifications, privacy
- **Edit Profile** – Photos, bio, discovery filters
- **Auth** – Login/signup (Supabase or demo mode)
- **Legal** – Privacy Policy & Terms of Service

## Quick Start

```bash
npm install
npm run dev
```

Open http://localhost:5173

## iOS App Store Build

### 1. Build & Open in Xcode

```bash
npm run ios
```

This builds the web app, syncs to iOS, and opens Xcode.

### 2. Configure in Xcode

- Select your **Team** (Apple Developer account)
- Set **Bundle Identifier** (e.g. `com.yourcompany.redcocoa`)
- Add **Signing & Capabilities** for Push Notifications if needed

### 3. Optional: Supabase Backend

Create a project at [supabase.com](https://supabase.com), then:

```bash
cp .env.example .env
# Edit .env with your VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY
```

Run the migrations in Supabase SQL Editor (in order):
1. `supabase/migrations/20250101000000_initial_schema.sql`
2. `supabase/migrations/20250102000000_passed_and_storage.sql`

Without Supabase, the app runs in **demo mode** with mock data. With Supabase configured, the app uses real profiles, matches, messages, blocks, reports, and photo storage.

### 4. App Store Connect

1. **Apple Developer Program** – $99/year at developer.apple.com
2. **Create App** – App Store Connect → My Apps → + → New App
3. **App Information** – Name, subtitle, category (Social Networking)
4. **Privacy Policy URL** – Host your privacy policy (e.g. `https://yoursite.com/privacy`)
5. **Age Rating** – 17+ (Dating)
6. **Screenshots** – Required sizes for each device
7. **Submit for Review**

### 5. Dating App Requirements

Apple requires for dating apps:

- Age verification (18+)
- Report/block functionality ✓
- Privacy policy ✓
- Terms of service ✓

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Start dev server |
| `npm run build` | Production build |
| `npm run ios` | Build + sync + open Xcode |
| `npm run sync` | Build + sync to native |

## Tech Stack

- React 19 + Vite 7
- React Router 7
- Capacitor 8 (iOS native)
- Supabase (optional backend)
- CSS variables
