# Red Cocoa (Native Swift/SwiftUI)

Native iOS dating app built with **Swift**, **SwiftUI**, and **UIKit** (where needed). Uses Supabase for backend.

## Setup

### Option A: XcodeGen (recommended)
```bash
brew install xcodegen
cd RedCocoaNative
xcodegen generate
open RedCocoa.xcodeproj
```
Then add Supabase URL and key in the target's Info or Build Settings.

### Option B: Manual Xcode project
1. Open Xcode → File → New → Project → iOS → App
2. Product Name: `RedCocoa`, Interface: **SwiftUI**
3. File → Add Package Dependencies → `https://github.com/supabase/supabase-swift` → add **Supabase**
4. Delete default `ContentView.swift`, drag the `RedCocoa` folder into the project
5. Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` to Info.plist

### Configure Supabase
Add to Info.plist or an xcconfig:
- `SUPABASE_URL` — your Supabase project URL
- `SUPABASE_ANON_KEY` — your Supabase anon key

### Run
Select a simulator or device, press **Run** (⌘R).

## Structure
- `RedCocoaApp.swift` — App entry point
- `Models/` — Profile, AppUser
- `Views/` — SwiftUI screens (Auth, Discover, Likes, Chats, Settings)
- `Services/` — AuthManager, SupabaseService
- `Data/` — MockData
- `Extensions/` — Color+Brand

## Backend
Uses the same Supabase schema as the web app. Run migrations from `supabase/migrations/` in your Supabase SQL Editor.
