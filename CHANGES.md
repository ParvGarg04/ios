# DailyFlow — What Was Added & Improved

## 🐛 Bug Fixes

### iOS App
- **Fixed `VerificationStatus` mismatch** — admin dashboard used different raw values than iOS. Unified to `pending_review / verified / rejected` everywhere.
- **Fixed `WaterLog.note` missing** — the model was missing the `note` field so notes were never saved/shown.
- **Fixed `TaskPriority.icon` missing** — the `icon` computed property was referenced in views but not defined in the model.
- **Fixed notifications firing outside 10 AM–10 PM window** — switched to `UNCalendarNotificationTrigger` with `repeats: true` so reminders repeat daily at the exact right times instead of one-shot triggers.
- **Fixed `CancelCurrentHourWaterReminders`** — old implementation incorrectly cancelled next-hour reminders; now only removes future slots within the current hour.
- **Fixed StorageService missing** — no `StorageService.swift` existed; views that called `StorageService.shared.uploadTaskAttachment` would crash at runtime.
- **Fixed `HomeViewModel` missing** — `HomeView` referenced a `HomeViewModel` that didn't exist.
- **Fixed `ImagePicker` & `CameraPicker` missing** — every sheet that needed photo picking would crash.
- **Fixed `AuthService` missing** — ViewModels referenced `AuthService.shared` which didn't exist.
- **Fixed streak update logic** — streak was read but never written back to Firestore.
- **Fixed admin dashboard `fetchPendingReviews`** — only fetched task submissions, ignoring water log reviews.
- **Fixed Firestore Timestamp conversion** — `tsToDate()` now safely handles both `Timestamp` and plain JS objects.
- **Fixed `deleteTask`** — soft-deletes (sets `isActive: false`) instead of hard deleting, preserving submission history.

## ✨ New Features

### iOS App
- **Camera picker** — members can now take a photo directly from the camera OR choose from the photo library (not just library-only).
- **Note field on water logs** — members can add a short note when logging hydration.
- **Note field on task submissions** — optional notes on task completions.
- **Overdue task highlighting** — tasks past their due time show a red due-time label.
- **Relative timestamps** — "Today, 3:42 PM", "Yesterday, 9:00 AM" throughout the history screen.
- **History grouped by day** with section headers (Today / Yesterday / date).
- **History filter chips** — All, Pending, Verified, Rejected, Tasks, Hydration.
- **Expandable history rows** — tap any row to reveal the attachment image and reviewer comment inline.
- **Profile stats strip** — streak, status, and role shown in a compact summary row.
- **Notification deep-link** — "Enable Notifications" alert links directly to iOS Settings.
- **Reminder window info card** — Hydration screen shows whether reminders are currently active or paused.
- **Progress ring gradient** — uses app gradient instead of flat blue.
- **Badge count cleared** on app foreground.
- **Water drop grid** — 12 drop icons on the hydration screen fill in as you log.

### Admin Dashboard
- **New Members page** — per-member cards showing total submissions, verified/rejected/pending counts, water logs, completion rate bar, and streak.
- **Combined reviews** — Reviews page now shows BOTH task submissions AND water log submissions in one queue.
- **Review modal** — clicking Verify/Reject opens a full modal with image preview, note display, open-full-image link, and a reviewer-note textarea.
- **Toast notifications** — success/error toasts on verify, reject, create task, update task.
- **Dashboard completion bar** — animated progress bar showing weekly completion rate.
- **Timeline member filter** — filter by individual member.
- **Timeline status + kind filters** — filter by Pending/Verified/Rejected and Task/Hydration simultaneously.
- **Timeline image thumbnails** — clickable thumbnail previews in the activity feed.
- **Task search** — search tasks by title or assigned member name.
- **Show/hide password** on login.
- **Admin role guard** — if a non-admin somehow logs in, they see an "Access Denied" screen with a sign-out button instead of a blank page.
- **Loading skeleton** — dashboard shows placeholder skeleton while data loads.
- **Refresh buttons** on every page.

## 🎨 UI / Design Improvements
- **Sidebar redesign** — dark sidebar with logo icon, active state highlight, user footer.
- **Card hover shadows** — cards lift slightly on hover.
- **Filter chips** use capsule shape with animated active state.
- **Empty states** on every list with contextual icons and messages.
- **Form validation errors** shown inline before the submit button.
- **CSS variables** for all colours — easy to re-theme.
- **Responsive review cards** — collapse to single column on narrow viewports.

## 📁 New Files Added
- `DailyFlow/Services/AuthService.swift`
- `DailyFlow/Services/StorageService.swift`
- `DailyFlow/Views/Components/ImagePicker.swift` (includes CameraPicker)
- `DailyFlow/ViewModels/HomeViewModel.swift`
- `admin-dashboard/src/components/Sidebar.tsx`
- `admin-dashboard/src/pages/MembersPage.tsx`
- `admin-dashboard/.env.example`
