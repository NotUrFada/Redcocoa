# App Store Readiness – Red Cocoa

## Current status: **Almost ready** (a few items left)

---

## ✅ Done

- [x] iOS project with Capacitor
- [x] Auth (signup, login, forgot password)
- [x] Privacy Policy (`public/privacy.html`)
- [x] Terms of Service
- [x] Account deletion flow
- [x] Block & report
- [x] Supabase backend
- [x] Photo upload
- [x] Location for discovery
- [x] Age rating: 17+ (Dating)

---

## ⚠️ Before submitting

### 1. Privacy permission strings (Info.plist)

Add these to `ios/App/App/Info.plist` so iOS can show permission prompts:

- **Location** – `NSLocationWhenInUseUsageDescription`
- **Photo Library** – `NSPhotoLibraryUsageDescription` (for profile photos)

### 2. Privacy Policy URL (hosted)

Apple needs a **public URL** for your Privacy Policy.

- Deploy `public/privacy.html` (e.g. Vercel, Netlify, GitHub Pages)
- Or deploy the full app and use `https://yourdomain.com/privacy`
- Add this URL in App Store Connect

### 3. App Store Connect setup

- [ ] Create app in App Store Connect
- [ ] Set Privacy Policy URL
- [ ] Age rating: **17+** (Dating)
- [ ] Screenshots (6.7", 6.5", 5.5" iPhone)
- [ ] App description, keywords, support URL
- [ ] Pricing (Free)

### 4. Production checklist

- [ ] Custom SMTP for auth emails (Supabase default: 2/hour)
- [ ] Add production redirect URLs in Supabase (password reset)
- [ ] Test on real device before submission

---

## Build & submit

```bash
npm run ios
```

In Xcode: select Team, set Bundle ID, then **Product → Archive**.  
Upload to App Store Connect and submit for review.
