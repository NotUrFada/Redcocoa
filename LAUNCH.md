# Red Cocoa – Launch Checklist

**iOS-only app.** Run through steps 1–4, then test on a device or simulator. Once that works, submit to the App Store.

---

## 1. Create a Supabase project

1. Go to [supabase.com](https://supabase.com) and sign in
2. Click **New Project**
3. Name the project (e.g. `red-cocoa`), set a database password, pick a region
4. Wait for the project to be created

---

## 2. Run migrations in the Supabase SQL Editor

1. In your Supabase project, open **SQL Editor**
2. For each migration file, create a new query, paste the contents, and click **Run**:
   - `supabase/migrations/20250101000000_initial_schema.sql`
   - `supabase/migrations/20250102000000_passed_and_storage.sql`
   - `supabase/migrations/20250103000000_ethnicity_hair.sql`
   - `supabase/migrations/20250104000000_humor_culture_features.sql`
   - `supabase/migrations/20250105000000_realtime_messages.sql`
   - `supabase/migrations/20250106000000_matches_insert_policy.sql`
   - `supabase/migrations/20250107000000_phone_in_profiles.sql`

---

## 3. Configure environment variables

1. In Supabase: **Project Settings** → **API**
2. Copy **Project URL** and **anon public** key
3. In your project root, create `.env`:
   ```
   VITE_SUPABASE_URL=https://xxxxx.supabase.co
   VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```
4. Restart the dev server if running

---

## 4. Redirect URLs (for auth)

Supabase → **Authentication** → **URL Configuration** → **Redirect URLs**. Add:

- `capacitor://localhost/#/auth/callback` (iOS app)
- `capacitor://localhost/#/reset-password` (iOS app)
- `http://localhost:5173/#/auth/callback` (dev in browser)
- `http://localhost:5173/#/reset-password` (dev in browser)

---

## 5. Email rate limits

Supabase default: **2 emails per hour** for signup, password reset, and email change. For production, configure [custom SMTP](https://supabase.com/docs/guides/auth/auth-smtp) in Supabase → Project Settings → Auth → SMTP.

---

## 6. Privacy Policy (required for App Store)

Host `public/privacy.html` at a public URL (e.g. GitHub Pages, Vercel, Netlify). Use that URL in App Store Connect.

---

## 7. Build and submit to the App Store

```bash
npm run ios
```

**In Xcode:**
1. Select your **Team**
2. Set **Bundle Identifier** (e.g. `com.yourcompany.redcocoa`)
3. Add **Signing & Capabilities**

**In App Store Connect:**
1. Create a new app
2. Set **Privacy Policy URL**
3. Set **Age Rating** 17+ (Dating)
4. Add screenshots for required device sizes
5. Submit for review
