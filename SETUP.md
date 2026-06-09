# DailyFlow — Step-by-Step Setup Guide

## Prerequisites

- **macOS** with Xcode 15+ (for iOS build)
- **XcodeGen** (`brew install xcodegen`)
- **Node.js** 18+ and npm
- **Firebase CLI** (`npm install -g firebase-tools`)
- Apple Developer account (for device testing / TestFlight)
- Firebase project (free Spark plan works for development)

---

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **Add project** → name it `dailyflow` (or your choice)
3. Disable Google Analytics (optional)
4. Click **Create project**

### Enable Services

| Service | Path in Console |
|---------|----------------|
| Authentication | Build → Authentication → Get started → Email/Password → Enable |
| Firestore | Build → Firestore Database → Create database → Start in **production mode** |
| Storage | Build → Storage → Get started |

---

## Step 2: Register iOS App

1. Firebase Console → Project Settings → **Add app** → iOS
2. Bundle ID: `com.dailyflow.app` (must match `project.yml`)
3. Download `GoogleService-Info.plist`
4. Place it at:

```
DailyFlow/DailyFlow/GoogleService-Info.plist
```

5. Copy the Firebase web config values — you'll need them for the admin dashboard.

---

## Step 3: Deploy Security Rules

```bash
cd firebase
firebase login
firebase use --add          # Select your project
firebase deploy --only firestore:rules,firestore:indexes,storage
```

Wait for composite indexes to finish building (Firebase Console → Firestore → Indexes).

---

## Step 4: Build the iOS App

On your Mac:

```bash
cd DailyFlow
xcodegen generate
open DailyFlow.xcodeproj
```

In Xcode:

1. Select your **Development Team** (Signing & Capabilities)
2. Select an iPhone simulator or connected device
3. Press **Cmd+R** to build and run

### First Launch

1. Tap **Create an account** to register as a member
2. Grant notification permission when prompted
3. The app schedules hydration reminders automatically (10 AM – 10 PM)

---

## Step 5: Create Admin Account

### Option A: Register then promote (recommended)

1. Create a user account in the iOS app or Firebase Console → Authentication
2. Download a Firebase **service account key** (Project Settings → Service accounts → Generate new private key)
3. Run the promotion script:

```bash
cd scripts
npm install
set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\serviceAccountKey.json   # Windows
# export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json  # macOS
node create-admin.js admin@yourdomain.com
```

### Option B: Manual via Firestore Console

1. Find the user's UID in Authentication
2. Create/edit document in `users/{uid}`:

```json
{
  "uid": "USER_UID_HERE",
  "name": "Admin",
  "email": "admin@yourdomain.com",
  "role": "admin",
  "streak": 0,
  "createdAt": "<server timestamp>"
}
```

---

## Step 6: Run Admin Dashboard

```bash
cd admin-dashboard
npm install
cp .env.example .env
```

Edit `.env` with your Firebase web app config:

```env
VITE_FIREBASE_API_KEY=AIza...
VITE_FIREBASE_AUTH_DOMAIN=dailyflow-xxxxx.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=dailyflow-xxxxx
VITE_FIREBASE_STORAGE_BUCKET=dailyflow-xxxxx.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=123456789
VITE_FIREBASE_APP_ID=1:123456789:web:abcdef
```

Start the dev server:

```bash
npm run dev
```

Open `http://localhost:5173` and sign in with your admin account.

### Deploy to Firebase Hosting (production)

```bash
npm run build
cd ../firebase
firebase deploy --only hosting
```

Your dashboard will be live at `https://your-project-id.web.app`.

---

## Step 7: Create Tasks (Admin)

1. Sign in to the admin dashboard
2. Go to **Task Management** → **Create Task**
3. Assign to a member, set title, due time, priority, and whether attachment is required
4. The member sees the task in the iOS app immediately

---

## Firestore Schema Reference

### `users/{uid}`

```json
{
  "uid": "string",
  "name": "string",
  "email": "string",
  "role": "member | admin",
  "streak": 0,
  "createdAt": "Timestamp"
}
```

### `tasks/{taskId}`

```json
{
  "taskId": "string",
  "userId": "string",
  "title": "string",
  "description": "string",
  "type": "simple | proofRequired",
  "dueTime": "Timestamp",
  "repeatInterval": "none | daily | weekly | hourly | custom",
  "customRepeatMinutes": 60,
  "priority": "normal | important | urgent",
  "requiresProof": false,
  "isActive": true,
  "createdAt": "Timestamp",
  "assignedBy": "admin_uid"
}
```

### `taskSubmissions/{submissionId}`

```json
{
  "submissionId": "string",
  "taskId": "string",
  "userId": "string",
  "taskTitle": "string",
  "imageURL": "string | null",
  "note": "string | null",
  "submittedAt": "Timestamp",
  "verificationStatus": "pending_review | verified | rejected",
  "adminComment": "string | null",
  "verifiedAt": "Timestamp | null"
}
```

### `waterLogs/{logId}`

```json
{
  "logId": "string",
  "userId": "string",
  "imageURL": "string | null",
  "uploadedAt": "Timestamp",
  "status": "pending_review | verified | rejected",
  "verifiedAt": "Timestamp | null",
  "adminComment": "string | null"
}
```

---

## Notification Logic

### Hydration Reminders

| Time | Behavior |
|------|----------|
| 10:00 AM – 10:00 PM | Hourly reminders at :00, :20, :40 |
| Outside window | No reminders |
| After submission | Cancels remaining reminders for current hour |
| Next day | Auto-reschedules at 10:00 AM |

### Task Reminders

- Main reminder at due time
- Follow-up at +20 min and +40 min if not completed
- Cancelled when task is submitted

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Build fails — missing GoogleService-Info.plist | Download from Firebase Console and add to Xcode project |
| Firestore permission denied | Deploy rules: `firebase deploy --only firestore:rules` |
| Admin login rejected | Verify `role: "admin"` in Firestore `users/{uid}` |
| Composite index error | Deploy indexes and wait for them to build |
| Notifications not showing | Check Settings → DailyFlow → Notifications; grant permission on first launch |
| Image upload fails | Deploy storage rules; check file is under 10 MB |

---

## Next Steps

- See [TESTFLIGHT.md](TESTFLIGHT.md) for App Store distribution
- Add a 1024×1024 app icon to `Assets.xcassets/AppIcon.appiconset`
- Configure your bundle ID and signing team in Xcode
