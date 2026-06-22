# Selah Notes 🪶

A dark-themed, gold-accented, **glassmorphic** notes app for Android with
folders, pinning, search, and a view/edit toggle. Built with Flutter.

## Features
- **Dark UI with strong glassmorphism** — frosted, blurred glass cards over
  a glowing dark background throughout
- **Folders** — create, open, delete (deleting a folder deletes its notes too)
- **Notes open in read-only "view mode" by default.** Tap the pencil
  icon in the top-right to unlock editing. Tap the checkmark to save
  and return to view mode.
- **Search** — search across every note's title and content from the home screen
- **Pin/favorite** — pin important notes so they float to the top of their folder
- **Sort** — sort folders and notes by newest, oldest, or name (A–Z / Z–A)
- **Move notes between folders** via the note card's menu
- **Share / export** a note as plain text to any app (WhatsApp, email, etc.)
- **Word count** shown while viewing/editing a note
- **Local persistent storage** via Hive — notes are saved to the
  device and survive app restarts (no internet/account needed)
- Empty notes are auto-discarded so you don't end up with junk entries

## How to build the APK yourself

You'll need:
1. **Flutter SDK** installed — https://docs.flutter.dev/get-started/install
2. **Android Studio** (or just the Android SDK command-line tools) installed
3. A device or emulator to test on (optional but recommended)

### Steps

```bash
cd selah_notes   # or whatever you named the unzipped folder
flutter pub get
flutter doctor
flutter build apk --release
```

Your APK will be generated at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Building via Codemagic
Make sure the workflow's **Build format** is set to **APK** (not Android
App Bundle / AAB) under the Build for platforms → Android settings —
otherwise you'll get a `.aab` file that can't be installed directly on
a phone.

### Notes on the project setup
- `minSdkVersion` is 21 (Android 5.0+) — covers virtually all active devices
- Release builds use **debug signing** so the build works out of the box
  with zero extra setup. Fine for personal use. Generate your own signing
  key before publishing to the Play Store.
- Hive's generated adapter files (`*.g.dart` in `lib/models/`) are
  pre-written by hand, so `build_runner` is not required.
- Gradle/AGP/Kotlin are pinned to a compatible, current set
  (Gradle 8.10.2, AGP 8.6.0, Kotlin 2.1.0, Java 17) to avoid the version
  mismatch errors common with older Flutter Android templates.
- A glass-card "S" launcher icon is included at all standard densities.

## Project structure
```
lib/
  main.dart                  → app entry point, sets up Hive + theme
  theme/app_theme.dart       → dark + gold color palette & ThemeData
  widgets/glass_card.dart    → reusable frosted-glass card + glow background
  models/
    note.dart / note.g.dart       → Note data model (+ isPinned) + Hive adapter
    folder.dart / folder.g.dart   → Folder data model + Hive adapter
  services/notes_database.dart    → Hive box read/write/delete/search logic
  screens/
    folders_screen.dart      → home screen: folders, search, sort
    notes_list_screen.dart   → notes inside a folder: pin, sort, move, delete
    note_view_screen.dart    → view/edit screen: pencil toggle, share, word count
```

## Customizing the look
All colors live in `lib/theme/app_theme.dart` under `AppColors`. The
main gold accent is `#D4AF37`. Glass strength (blur amount, opacity) is
controlled in `lib/widgets/glass_card.dart` via `blurSigma` and
`AppColors.glassFill`.

## What's still local-only (not yet built)
Notes currently live only on the device (Hive local database) — there's
no Google Drive / cloud sync yet. If you uninstall the app or switch
phones, notes won't carry over unless you've shared/exported them
manually. Drive sync is a larger feature requiring your own Google Cloud
Console project + OAuth setup — ask if you'd like to add it next.

