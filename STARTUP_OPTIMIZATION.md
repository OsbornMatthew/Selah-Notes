# Selah Notes — Startup Optimizations

## What was changed and why

### 1. App Icon — All sizes replaced ✅
All Android mipmap densities (mdpi → xxxhdpi) updated with your new gold icon.
Native splash also uses the icon centered on a dark `#111111` background.

### 2. Native Splash Screen (eliminates blank/white flash) ✅
`flutter_native_splash` added to pubspec.
**Run this ONE TIME after `flutter pub get`:**
```
flutter pub run flutter_native_splash:create
```
This injects a native Android splash that shows your icon *before* the Flutter
engine even starts — the blank screen / white flash at cold start disappears.

### 3. Faster FoldersScreen load ✅
**Before:** `_loadFolders()` set `isLoading = true` and waited for 3 parallel
Firestore futures (folders + notes + archive password) before showing anything.
If the server was slow, this could block the screen for 3–8 seconds.

**After:** The screen renders immediately using Firestore's local cache
(typically <30 ms). The archive password pre-warm runs silently after the UI
is already painted — the user never waits for it.

### 4. Smaller Firestore cache (50 MB vs 100 MB) ✅
Firestore has to open and verify its on-disk cache at every cold start.
Smaller cap = faster cold-start verification.

### 5. Native splash background matches app theme ✅
`launch_background.xml` updated to `#111111` with the icon centered —
no jarring color flash between native splash and Flutter splash.

### 6. `connectivity_plus` added to pubspec ✅
Was already imported in `firebase_sync_service.dart` but missing from
pubspec — added so the sync service builds cleanly.

## Build commands
```bash
flutter pub get
flutter pub run flutter_native_splash:create   # ONE TIME
flutter build apk --release
```
