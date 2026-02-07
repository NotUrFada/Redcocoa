# Red Cocoa – App Store Submission Guide

Follow these steps to submit Red Cocoa to the App Store.

---

## Prerequisites

- [ ] Apple Developer account ($99/year) – [developer.apple.com](https://developer.apple.com)
- [ ] Supabase configured and migrations run
- [ ] Privacy Policy hosted at a public URL
- [ ] App tested on a real device

---

## 1. Apple Developer Program

1. Enroll at [developer.apple.com/programs](https://developer.apple.com/programs)
2. Wait for approval (usually 24–48 hours)

---

## 2. App Store Connect Setup

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in:
   - **Platform:** iOS
   - **Name:** Red Cocoa
   - **Primary Language:** English (or your choice)
   - **Bundle ID:** (create in step 3 if needed)
   - **SKU:** e.g. `redcocoa-001`
4. Click **Create**

---

## 3. Xcode Project Setup

1. Open the project: `npm run ios` (or open `ios/App/App.xcworkspace` in Xcode)
2. Select the **App** target → **Signing & Capabilities**
3. Set:
   - **Team:** Your Apple Developer team
   - **Bundle Identifier:** e.g. `com.yourcompany.redcocoa` (must match App Store Connect)
   - **Signing:** Automatically manage signing
4. If you get a provisioning error, go to **Xcode** → **Settings** → **Accounts** and add your Apple ID

---

## 4. App Store Connect – App Information

In App Store Connect, under your app:

1. **App Information**
   - **Privacy Policy URL:** Your hosted privacy policy (required)
   - **Category:** Social Networking
   - **Secondary Category:** Lifestyle (optional)

2. **Pricing and Availability**
   - **Price:** Free (or set your price)
   - **Availability:** All countries (or select regions)

3. **Age Rating**
   - Click **Edit** next to Age Rating
   - Answer the questionnaire (dating apps typically get **17+**)
   - **Mature/Suggestive Themes:** Yes
   - **Unrestricted Web Access:** No (unless you have in-app browser)
   - **User-Generated Content:** Yes (profiles, messages)

---

## 5. Prepare Screenshots

Apple requires screenshots for each device size. You need:

| Device | Size | Count |
|--------|------|-------|
| iPhone 6.7" | 1290 x 2796 px | 3–10 |
| iPhone 6.5" | 1284 x 2778 px | 3–10 |
| iPhone 5.5" | 1242 x 2208 px | 3–10 |

**How to capture:**
- Run the app on a simulator or device
- Use **Cmd + S** in Simulator or **Device** → **Screenshot**

**Or:**
- Use [App Store Screenshot](https://www.appstorescreenshot.com) or similar tools

---

## 6. App Store Connect – Version Information

1. In your app, go to **App Store** tab (left sidebar)
2. Under **iOS App**, click **+** to add a version (e.g. 1.0)
3. Fill in:

| Field | What to enter |
|-------|---------------|
| **Promotional Text** | Short line shown above description (optional, can update anytime) |
| **Description** | Full app description (2–4 paragraphs) |
| **Keywords** | Comma-separated, no spaces (e.g. `dating,match,ginger,redhead`) |
| **Support URL** | Your website or support page |
| **Marketing URL** | Optional |
| **Screenshots** | Drag and drop for each device size |
| **App Preview** | Optional video (15–30 sec) |
| **App Icon** | 1024×1024 px (already in project) |

---

## 7. Build and Upload

1. In Xcode, select **Any iOS Device** (or a connected device) as the run destination
2. **Product** → **Archive**
3. Wait for the archive to complete
4. When Organizer opens, select your archive → **Distribute App**
5. Choose **App Store Connect** → **Upload**
6. Follow the prompts (default options are fine)
7. Wait for upload to complete (5–15 minutes)

---

## 8. Submit for Review

1. In App Store Connect, go to your app → **App Store** tab
2. Under **Build**, click **+** and select the build you just uploaded
3. Wait for the build to appear (can take 10–30 minutes)
4. Fill in **Export Compliance** (usually "No" for most apps)
5. Fill in **Advertising Identifier** (usually "No" if you don't use ads)
6. **Content Rights:** Confirm you have rights to all content
7. **Age Rating:** Should already be set
8. Click **Add for Review** → **Submit to App Review**

---

## 9. After Submission

- **Review time:** Usually 24–48 hours
- **Status:** Check **App Store Connect** → **My Apps** → your app
- **Rejection:** If rejected, Apple provides a reason. Fix issues and resubmit.

---

## Common Rejection Reasons (Dating Apps)

1. **Privacy Policy missing or invalid** – Must be hosted and accessible
2. **Age rating** – Dating apps often need 17+
3. **Login/signup broken** – Test auth flow thoroughly
4. **Incomplete functionality** – All features must work
5. **Guideline 4.2 (Minimum Functionality)** – App must be substantial

---

## Quick Checklist

- [ ] Apple Developer account active
- [ ] App created in App Store Connect
- [ ] Bundle ID matches in Xcode and App Store Connect
- [ ] Privacy Policy URL set and live
- [ ] Age rating 17+ (or appropriate)
- [ ] Screenshots for required device sizes
- [ ] App description and keywords filled
- [ ] Build archived and uploaded
- [ ] Build selected in version
- [ ] Submitted for review
