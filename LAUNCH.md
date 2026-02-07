# Red Cocoa – Launch Checklist

**Before you launch:** Run through steps 1–4, then test signup, discovery, likes, passes, and chat locally. Once that works, you're ready to deploy.

---

## 1. Create a Supabase project

1. Go to [supabase.com](https://supabase.com) and sign in (or create an account)
2. Click **New Project**
3. Choose an organization, name the project (e.g. `red-cocoa`), set a database password, and pick a region
4. Wait for the project to be created

---

## 2. Run migrations in the Supabase SQL Editor

1. In your Supabase project, open **SQL Editor** in the left sidebar
2. Click **New query**
3. Copy the contents of `supabase/migrations/20250101000000_initial_schema.sql` and paste into the editor
4. Click **Run** (or press Cmd/Ctrl + Enter)
5. Create another new query
6. Copy the contents of `supabase/migrations/20250102000000_passed_and_storage.sql` and paste into the editor
7. Click **Run**
8. Repeat for `20250103000000_ethnicity_hair.sql`, `20250104000000_humor_culture_features.sql`, `20250105000000_realtime_messages.sql` (enables real-time chat), `20250106000000_matches_insert_policy.sql` (enables likes/matches), and `20250107000000_phone_in_profiles.sql` (phone number in settings)

---

## 3. Configure environment variables

1. In Supabase: **Project Settings** → **API**
2. Copy **Project URL** and **anon public** key
3. In your project root, edit `.env`:
   ```
   VITE_SUPABASE_URL=https://xxxxx.supabase.co
   VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```
4. Restart the dev server (`npm run dev`) if it’s running

---

## 4. Redirect URLs (for password reset)

**Verify real data:** After signing in, the Discover feed should show real profiles from your database (or "No matches yet" if empty). If you see placeholder names like "Julian" or "Sophia", you're in demo mode — check that `.env` has the correct values and restart the dev server.

For "Forgot password" and email confirmation to work, add your app URLs to Supabase:

1. Supabase Dashboard → **Authentication** → **URL Configuration** → **Redirect URLs**
2. Add: `http://localhost:5173/auth/callback` (development)
3. Add: `http://localhost:5173/reset-password` (development)
4. Add your production URLs, e.g. `https://yourdomain.com/auth/callback` and `https://yourdomain.com/reset-password`

---

## 5. Email rate limits (Supabase default)

Supabase’s built-in email service is limited to **2 emails per hour** for signup, password reset, and email change combined. If you see “Email rate limit exceeded”:

- **Short term:** Wait about an hour before trying again.
- **Long term:** Configure [custom SMTP](https://supabase.com/docs/guides/auth/auth-smtp) (e.g. Resend, SendGrid, AWS SES) in Supabase → Project Settings → Auth → SMTP. This removes the limit.

---

## 6. Host the Privacy Policy (for App Store Connect)

Apple requires a public URL for your Privacy Policy.

**Option A – Deploy the app**

- Deploy the built app (e.g. Vercel, Netlify, GitHub Pages)
- Use: `https://yourdomain.com/privacy` (or the route where the privacy page lives)

**Option B – Standalone page**

- Deploy `public/privacy.html` to any static host
- Use: `https://yoursite.com/privacy.html`

**Option C – GitHub Pages**

```bash
# Build and deploy the dist folder to GitHub Pages
npm run build
# Then push the dist folder to a gh-pages branch or use a GitHub Action
```

---

## 7. Deploy the web app (optional)

If you want a web version live before or alongside the iOS app:

```bash
npm run build
```

Deploy the `dist/` folder to Vercel, Netlify, or your host. Set the same `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` as build environment variables.

Add your production URL to Supabase redirect URLs (step 4).

---

## 8. Build and submit to the App Store

```bash
npm run ios
```

This builds the web app, syncs to the iOS project, and opens Xcode.

**In Xcode:**

1. Select your **Team** (Apple Developer account)
2. Set **Bundle Identifier** (e.g. `com.yourcompany.redcocoa`)
3. Add **Signing & Capabilities** (e.g. Push Notifications if needed)

**In App Store Connect:**

1. Create a new app
2. Set **Privacy Policy URL** (from step 6)
3. Choose **Age Rating** 17+ (Dating)
4. Add screenshots for required device sizes
5. Submit for review
