# App Store Submission Checklist – Red Cocoa

Use this list before submitting to the App Store.

---

## 1. Xcode project

- [ ] **Version**: Info.plist has `CFBundleShortVersionString` = `1.0.0` (or your chosen version). Bump `CFBundleVersion` (build number) for each upload.
- [ ] **Signing**: Select your **Team** and a **Distribution** provisioning profile (or “Automatically manage signing” with the correct Apple ID).
- [ ] **Bundle ID**: Matches the App ID in App Store Connect (e.g. `com.redcocoa.app`).
- [ ] **Capabilities**: In **Signing & Capabilities**, ensure:
  - **Sign in with Apple** (required if you offer other social login).
  - **Push Notifications** if you send remote notifications (messages).
- [ ] **Build**: Choose **Any iOS Device** (or a generic device), then **Product → Archive**. Fix any errors before archiving.

---

## 2. App Store Connect

- [ ] **App**: Create the app in [App Store Connect](https://appstoreconnect.apple.com) with the same bundle ID.
- [ ] **Name & subtitle**: App name and subtitle (if used).
- [ ] **Privacy Policy URL**: Required. A hostable copy is in `RedCocoaNative/PrivacyPolicy.html`. Upload it to your website or GitHub Pages (e.g. `https://yoursite.com/privacy` or `https://yourusername.github.io/redcocoa/privacy`), then add that URL in App Store Connect (App Information and version metadata).
- [ ] **Category**: e.g. **Dating** (or Social Networking). Set primary and optional secondary.
- [ ] **Age rating**: Complete the questionnaire (e.g. dating + user content often results in 17+). Set the correct rating.
- [ ] **Pricing**: Free or paid; select availability (countries).
- [ ] **Screenshots**: At least one screenshot per required device size (e.g. 6.7", 6.5", 5.5" for iPhone). Use Simulator or device.
- [ ] **Description & keywords**: Short description, full description, and keywords for search.
- [ ] **Support URL**: A URL where users can get help (e.g. your site or support email page).
- [ ] **Export compliance**: App uses only standard encryption (HTTPS, etc.), so you can answer “No” to using non-exempt encryption. The project has `ITSAppUsesNonExemptEncryption` = false to support this.

---

## 3. Content & legal

- [ ] **Sign in with Apple**: If you offer Google/email/phone sign-in, you must also offer Sign in with Apple (you already have the capability).
- [ ] **Privacy Nutrition Labels**: In App Store Connect, declare data collection (e.g. name, email, photos, location, identifiers) and usage. Match what the app actually does.
- [ ] **Terms & Privacy**: In-app Terms and Privacy Policy match (or link to) what you state in App Store Connect.

---

## 4. Before you submit

- [ ] **Test on a real device**: Install the release build and test sign-in, discovery, matching, chat, profile edit, and notifications (if enabled).
- [ ] **Remove or disable debug-only code**: No test accounts or debug logs in the build you submit.
- [ ] **Supabase**: Production Supabase URL and anon key are in Info.plist (or use a config that points to production). Ensure RLS and auth are correct for production.

---

## 5. Upload and submit

1. In Xcode: **Product → Archive**.
2. In the Organizer, select the archive and click **Distribute App** → **App Store Connect** → **Upload**.
3. In App Store Connect, open your app → **TestFlight** to see the build, then go to the app version and select that build.
4. Complete all required fields (screenshots, description, etc.) and submit for **App Review**.

---

## Quick reference

| Item              | Where                          |
|-------------------|---------------------------------|
| Version           | Info.plist / Xcode General      |
| Bundle ID         | Xcode → Signing & Capabilities  |
| Privacy Policy URL| App Store Connect → App Info    |
| Sign in with Apple | Xcode → Capabilities          |
| Push Notifications | Xcode → Capabilities (if used) |

Good luck with your submission.
