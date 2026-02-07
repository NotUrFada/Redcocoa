# Red Cocoa – Task List

Concrete tasks to complete. Check off each when done.

---

## Supabase Setup

- [ ] Create a Supabase project at supabase.com
- [ ] Run migration 1: copy `supabase/migrations/20250101000000_initial_schema.sql` into SQL Editor, click Run
- [ ] Run migration 2: copy `supabase/migrations/20250102000000_passed_and_storage.sql` into SQL Editor, click Run
- [ ] Run migration 3: copy `supabase/migrations/20250103000000_ethnicity_hair.sql` into SQL Editor, click Run
- [ ] Run migration 4: copy `supabase/migrations/20250104000000_humor_culture_features.sql` into SQL Editor, click Run
- [ ] Run migration 5: copy `supabase/migrations/20250105000000_realtime_messages.sql` into SQL Editor, click Run
- [ ] Run migration 6: copy `supabase/migrations/20250106000000_matches_insert_policy.sql` into SQL Editor, click Run
- [ ] Run migration 7: copy `supabase/migrations/20250107000000_phone_in_profiles.sql` into SQL Editor, click Run

---

## Environment

- [ ] Create `.env` in project root
- [ ] Add `VITE_SUPABASE_URL` with your Supabase project URL from Project Settings → API
- [ ] Add `VITE_SUPABASE_ANON_KEY` with your anon key from Project Settings → API
- [ ] Restart dev server after editing `.env`

---

## Supabase Auth URLs

- [ ] Supabase Dashboard → Authentication → URL Configuration → Redirect URLs
- [ ] Add `http://localhost:5173/auth/callback`
- [ ] Add `http://localhost:5173/reset-password`
- [ ] Add production callback URL (e.g. `https://yourdomain.com/auth/callback`) when you have a production URL
- [ ] Add production reset URL (e.g. `https://yourdomain.com/reset-password`) when you have a production URL

---

## Privacy Policy (Required for App Store)

- [ ] Host `public/privacy.html` at a public URL (e.g. Vercel, Netlify, GitHub Pages)
- [ ] Record the URL for App Store Connect

---

## Web Deployment (Optional)

- [ ] Run `npm run build`
- [ ] Deploy the `dist/` folder to Vercel, Netlify, or your host
- [ ] Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` as build environment variables in your host
- [ ] Add the production URL to Supabase redirect URLs

---

## iOS / App Store

- [ ] Enroll in Apple Developer Program ($99/year)
- [ ] Run `npm run ios` to open Xcode
- [ ] In Xcode: select your Team
- [ ] In Xcode: set Bundle Identifier (e.g. `com.yourcompany.redcocoa`)
- [ ] In Xcode: connect a device or simulator, click Run to verify build
- [ ] In Xcode: Product → Archive
- [ ] In Xcode: Distribute App → App Store Connect → Upload
- [ ] App Store Connect: create new app (My Apps → + → New App)
- [ ] App Store Connect: set Privacy Policy URL
- [ ] App Store Connect: set Category to Social Networking
- [ ] App Store Connect: complete Age Rating questionnaire (expect 17+ for dating)
- [ ] App Store Connect: add screenshots for iPhone 6.7", 6.5", and 5.5"
- [ ] App Store Connect: write app description
- [ ] App Store Connect: add keywords
- [ ] App Store Connect: select the uploaded build
- [ ] App Store Connect: submit for review

---

## Verification (Before Launch)

- [ ] Sign up with a new email
- [ ] Complete onboarding
- [ ] See real profiles in Discover (not "Julian" or "Sophia" from demo)
- [ ] Like a profile
- [ ] Pass a profile
- [ ] Open a chat and send a message
- [ ] Save phone number in Settings
- [ ] Log out and log back in
