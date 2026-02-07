# Testing Red Cocoa on Your Phone & With Others

## Option 1: Quick test on your own phone (same WiFi)

1. **Start the dev server** (exposes it on your local network):
   ```bash
   npm run dev -- --host
   ```
   Or add to `package.json` scripts: `"dev:mobile": "vite --host"` and run `npm run dev:mobile`

2. **Find your computer's IP address:**
   - Mac: System Settings → Network → Wi‑Fi → Details, or run `ipconfig getifaddr en0`
   - Windows: `ipconfig` and look for IPv4 Address

3. **On your phone** (same WiFi as your computer):
   - Open Safari (iOS) or Chrome (Android)
   - Go to `http://YOUR_IP:5173` (e.g. `http://192.168.1.100:5173`)

4. **Optional – add to home screen** for an app-like experience:
   - iOS: Share → Add to Home Screen
   - Android: Menu → Add to Home Screen

---

## Option 2: Deploy to the web (share a link with testers)

Deploy the built app so anyone with the URL can test it.

### Vercel (recommended)

1. Push your code to GitHub
2. Go to [vercel.com](https://vercel.com) and sign in with GitHub
3. Import your repo → Deploy
4. Add env vars: `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`
5. Share the URL (e.g. `https://red-cocoa.vercel.app`)

### Netlify

1. Push to GitHub
2. Go to [netlify.com](https://netlify.com) → Add new site → Import from Git
3. Build command: `npm run build`
4. Publish directory: `dist`
5. Add env vars in Site settings → Environment variables

### Share with testers

- Send them the URL
- They can add it to their home screen for an app-like feel
- Works on both iOS and Android

---

## Option 3: Native iOS app via TestFlight (for iPhone testers)

Use TestFlight to distribute the iOS app to up to 10,000 testers.

### Prerequisites

- Apple Developer account ($99/year)
- Mac with Xcode

### Steps

1. **Build and sync:**
   ```bash
   npm run ios
   ```

2. **In Xcode:**
   - Select your Team
   - Set Bundle ID (e.g. `com.yourcompany.redcocoa`)
   - Product → Archive

3. **In App Store Connect:**
   - Create the app (if needed)
   - Add a TestFlight build
   - Add internal or external testers
   - Testers get an email and install via the TestFlight app

---

## Option 4: Android (if you add it)

To support Android:

```bash
npm install @capacitor/android
npx cap add android
npm run build
npx cap sync android
npx cap open android
```

Then build an APK or AAB and share via Google Play internal testing or direct APK install.

---

## Checklist before sharing

- [ ] `.env` has `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`
- [ ] Supabase migrations are run
- [ ] Auth (signup/login) works
- [ ] Privacy policy is hosted (needed for App Store)
