# DailyFlow

A production-ready iOS wellness and routine-tracking app built with **SwiftUI** and **Firebase**. DailyFlow helps members manage hydration reminders, complete assigned tasks, and submit optional attachments — all through a clean, neutral productivity UI.

## Project Structure

```
remapp/
├── DailyFlow/                  # iOS SwiftUI app
│   ├── DailyFlow/              # Source code (MVVM)
│   │   ├── Models/
│   │   ├── ViewModels/
│   │   ├── Views/
│   │   ├── Services/
│   │   └── Utilities/
│   └── project.yml             # XcodeGen project spec
├── admin-dashboard/            # React reviewer dashboard
├── firebase/                   # Firestore & Storage rules
├── scripts/                    # Admin setup utilities
├── SETUP.md                    # Step-by-step setup guide
└── TESTFLIGHT.md               # TestFlight deployment guide
```

## Features

### iOS App (Member)
- Email/password authentication with stay-logged-in
- Home dashboard with progress, streaks, and pending tasks
- Hydration tracking with hourly reminders (10 AM – 10 PM)
- Custom tasks with simple or attachment-required completion
- Submission history with review status
- Profile settings (notifications, dark mode, logout)
- Local push notifications

### Admin Dashboard (Reviewer)
- Secure admin-only login
- Pending review queue (tasks + hydration)
- Verify, reject, and comment on submissions
- Task creation and management
- Member timeline and statistics
- Firebase Hosting deployment ready

## Tech Stack

| Layer | Technology |
|-------|-----------|
| iOS UI | SwiftUI |
| Architecture | MVVM |
| Backend | Firebase Auth, Firestore, Storage |
| Notifications | iOS Local Notifications (UNUserNotificationCenter) |
| Admin UI | React + Vite + TypeScript |
| Security | Firestore & Storage security rules with role-based access |

## Quick Start

See [SETUP.md](SETUP.md) for the complete setup guide.

```bash
# 1. Create Firebase project and download GoogleService-Info.plist
# 2. Generate Xcode project (on macOS):
cd DailyFlow && xcodegen generate && open DailyFlow.xcodeproj

# 3. Deploy Firebase rules:
cd firebase && firebase deploy

# 4. Run admin dashboard:
cd admin-dashboard && npm install && cp .env.example .env
# Edit .env with Firebase config, then:
npm run dev
```

## Firestore Collections

| Collection | Description |
|-----------|-------------|
| `users` | Member and admin profiles |
| `tasks` | Admin-assigned tasks |
| `taskSubmissions` | Task completion records |
| `waterLogs` | Hydration update records |

## Security

- Members can only read/write their own data
- Only admins can create tasks and verify submissions
- Image uploads limited to 10 MB, image types only
- Role stored in Firestore `users` collection

## License

Private project. All rights reserved.
