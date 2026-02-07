# Red Cocoa

iOS-only dating app built with **Swift**, **SwiftUI**, and **UIKit**. Uses Supabase for backend.

## Tech Stack

- **Swift** – Language
- **SwiftUI** – Declarative UI
- **UIKit** – Used where needed (e.g. `UITextField` styling, legacy components)
- **Supabase** – Auth, database, storage, realtime

## Quick Start

### 1. Open in Xcode
Open `RedCocoaNative/RedCocoa.xcodeproj` in Xcode (or create a new project and add the `RedCocoa` source folder — see `RedCocoaNative/README.md`).

### 2. Add Supabase
- File → Add Package Dependencies...
- URL: `https://github.com/supabase/supabase-swift`
- Add **Supabase** to your target

### 3. Configure Supabase
Add to Info.plist (or a config file):
- `SUPABASE_URL` – your Supabase project URL
- `SUPABASE_ANON_KEY` – your Supabase anon key

### 4. Run
Select a simulator or device, press **Run** (⌘R).

## Project Structure

```
RedCocoaNative/
  RedCocoa/
    RedCocoaApp.swift      # App entry
    Models/                # Profile, AppUser
    Views/                 # SwiftUI screens
    Services/              # AuthManager, Supabase
    Data/                  # MockData
    Extensions/            # Color+Brand
```

## Features

- **Auth** – Login, signup, forgot password
- **Onboarding** – Welcome slides
- **Discover** – Swipeable profile cards (pass/like)
- **Likes** – People who liked you
- **Chats** – Message list
- **Profile/Settings** – Account, preferences

## Backend

Uses the same Supabase schema as before. Run migrations from `supabase/migrations/` in the Supabase SQL Editor. See `LAUNCH.md` for setup.

## Legacy

The previous React + Capacitor app is in `src/` and `ios/`. The native Swift app in `RedCocoaNative/` is the primary implementation.
