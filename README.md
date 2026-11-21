# TickFlow — Plan simply, finish smoothly.

Modern Material 3 Android Todo & Productivity app built with **Flutter** and configured for **100% Cloud Compilation via GitHub Actions** (no local Android Studio or heavy PC required).

## Features Included
- **Tasks & Smart Filters:** All, Today, Upcoming, Overdue, Completed, plus real-time search.
- **Priorities & Custom Categories:** High / Medium / Low priority badges and color-coded categories (`Personal`, `Work`, `Study`, `Shopping` + add your own).
- **Sub-tasks (Checklists):** Break big tasks into smaller steps with live completion tracking.
- **Reminders & Recurring Tasks:** Local Android notifications with Daily, Weekly, and Monthly auto-repeat.
- **Calendar & Productivity Stats:** Interactive 14-day schedule strip, daily streak tracker, 7-day completion chart, and category breakdown.
- **Material 3 Dark & Light Mode:** Indigo-to-Teal theme matching the TickFlow logo.
- **Offline Storage & JSON Backup:** Works 100% offline with JSON Export/Import backup in Settings.

## Cloud Build via GitHub Actions
Every time you push code to the `main` branch, `.github/workflows/build_android.yml` automatically builds:
1. `TickFlow-Android-APK` (`app-release.apk`) — Install directly on your Android phone.
2. `TickFlow-PlayStore-AAB` (`app-release.aab`) — Ready for Google Play Console.

## Quick Future Updates (Windows)
After your initial GitHub setup, simply double-click `push_update.bat` (or run `git add . && git commit -m "update" && git push` in PowerShell/CMD) to push changes and trigger a fresh cloud APK build.
