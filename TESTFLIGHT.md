# DailyFlow — TestFlight Deployment Guide

## Prerequisites

- Apple Developer Program membership ($99/year)
- macOS with Xcode 15+
- Firebase project configured (see [SETUP.md](SETUP.md))
- App icon (1024×1024 PNG) added to `AppIcon.appiconset`

---

## Step 1: Prepare the App

### App Icon

1. Create a 1024×1024 PNG icon (wellness/productivity style — water drop, leaf, or checklist motif)
2. In Xcode: `Assets.xcassets` → `AppIcon` → drag icon into the 1024 slot

### Bundle ID & Signing

1. Open `DailyFlow.xcodeproj` in Xcode
2. Select the **DailyFlow** target → **Signing & Capabilities**
3. Set **Team** to your Apple Developer team
4. Set **Bundle Identifier** to a unique ID (e.g. `com.yourcompany.dailyflow`)
5. Update the same bundle ID in:
   - Firebase Console (re-download `GoogleService-Info.plist` if changed)
   - `DailyFlow/project.yml` → `PRODUCT_BUNDLE_IDENTIFIER`

### Version & Build Number

In Xcode → General:

| Field | Value |
|-------|-------|
| Version | `1.0.0` |
| Build | `1` (increment for each upload) |

### Privacy Descriptions

Already configured in `Info.plist`:
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`

---

## Step 2: Create App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. **My Apps** → **+** → **New App**
3. Fill in:
   - **Platform**: iOS
   - **Name**: DailyFlow
   - **Primary Language**: English
   - **Bundle ID**: select your registered bundle ID
   - **SKU**: `dailyflow-001`
4. Click **Create**

### App Information

| Field | Suggested Value |
|-------|----------------|
| Category | Health & Fitness (primary), Productivity (secondary) |
| Content Rights | Does not contain third-party content |
| Age Rating | 4+ |

### Privacy Policy

You need a privacy policy URL. Host a simple page covering:
- Data collected (email, task submissions, photos)
- Firebase as data processor
- How to delete account (in-app Profile → Delete Account)

---

## Step 3: Archive & Upload

### In Xcode

1. Select **Any iOS Device (arm64)** as build destination (not simulator)
2. **Product** → **Archive**
3. Wait for archive to complete
4. Organizer window opens → select archive → **Distribute App**
5. Choose **App Store Connect** → **Upload**
6. Follow prompts (automatic signing, include bitcode: no, upload symbols: yes)
7. Click **Upload**

### Verify Upload

1. App Store Connect → your app → **TestFlight** tab
2. Build appears under **iOS Builds** (processing takes 5–30 minutes)
3. If "Missing Compliance" appears, click and answer **No** for encryption (uses standard HTTPS only)

---

## Step 4: Configure TestFlight

### Internal Testing (up to 100 testers)

1. TestFlight → **Internal Testing** → create group
2. Add Apple ID emails of testers
3. Select the uploaded build
4. Testers receive email invite → install via TestFlight app

### External Testing (up to 10,000 testers)

1. TestFlight → **External Testing** → create group
2. Fill in **What to Test** notes:

```
DailyFlow is a wellness and routine tracker. Please test:
- Account creation and login
- Hydration logging and reminders
- Task completion (with and without attachments)
- History and profile settings
```

3. Submit for **Beta App Review** (required for external testers, usually 24–48 hours)

---

## Step 5: Pre-Release Checklist

- [ ] Firebase rules deployed to production
- [ ] Admin account created and dashboard accessible
- [ ] `GoogleService-Info.plist` matches production Firebase project
- [ ] Notifications work on a physical device (not simulator)
- [ ] Camera and photo library permissions work
- [ ] Tested on iPhone (portrait only)
- [ ] Dark mode renders correctly
- [ ] Account deletion works
- [ ] Admin can create tasks and verify submissions

---

## Step 6: Submit for App Store Review (Optional)

When ready for public release:

1. App Store Connect → **App Store** tab
2. Fill in screenshots (6.7" and 6.1" iPhone required)
3. Write description:

```
DailyFlow helps you build healthy routines and stay on track with your daily wellness goals.

• Track hydration with smart hourly reminders
• Complete assigned tasks and submit updates
• View your progress, streaks, and history
• Clean, distraction-free interface
• Dark mode support

Stay consistent. Stay balanced. DailyFlow.
```

4. Select the TestFlight build
5. Submit for review

---

## Build Increment Workflow

For each new TestFlight build:

```bash
# 1. Increment build number in Xcode (e.g. 1 → 2)
# 2. Archive and upload
# 3. TestFlight auto-notifies testers of new build
```

---

## Common Rejection Reasons & Fixes

| Reason | Fix |
|--------|-----|
| Missing privacy policy | Add URL in App Store Connect |
| Crash on launch | Test release build on device before upload |
| Incomplete metadata | Add all required screenshots and descriptions |
| Guideline 4.2 (minimum functionality) | Ensure tasks, hydration, and history all work |
| Missing purpose strings | Verify camera/photo usage descriptions in Info.plist |

---

## Support

- [Apple TestFlight Documentation](https://developer.apple.com/testflight/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
