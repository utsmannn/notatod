# Notatod

Notatod is a lightweight menubar notes app for macOS.

It is built for quick capture: open from the menu bar, write in Markdown, and get back to work without switching into a full notes app.

## Current stack

- SwiftUI
- SwiftData
- XcodeGen
- MarkdownUI
- Splash
- HotKey

## Features

- Menubar-first macOS app
- Multiple notes with search and pin support
- Markdown editing with preview
- Image paste / drag and drop support
- Autosave-first editing flow
- Google OAuth sign-in for sync
- Google Drive push sync for local note changes

## Sync status

Current sync implementation is intentionally narrow:

- local-first
- Google Drive push sync
- no pull sync yet
- no conflict resolution yet
- no background backend

Remote storage currently uses a dedicated `.notatod` folder in the user’s Google Drive.

## Project structure

```text
Notatod/
├── App/
├── Models/
├── Services/
│   └── Sync/
├── Shell/
├── State/
├── Views/
├── Resources/
└── Config/
```

## Requirements

- macOS 14+
- Xcode 17+
- XcodeGen

## Getting started

### 1. Generate the project

```bash
xcodegen generate
```

### 2. Add local sync config (optional)

If you want to test Google Drive sync, copy the example plist:

```bash
cp Notatod/Config/SyncSecrets.example.plist Notatod/Config/SyncSecrets.plist
```

Then fill these values:

- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `GOOGLE_REDIRECT_URI`

`SyncSecrets.plist` is intended to stay untracked.

### 3. Build

```bash
xcodebuild build -scheme Notatod -project Notatod.xcodeproj
```

### 4. Run

You can launch from Xcode, or use the helper script:

```bash
./scripts/dev.sh
```

## Notes for development

- `project.yml` is the source of truth for the Xcode project.
- After adding or removing Swift files, regenerate the project with `xcodegen generate`.
- The generated `Notatod.xcodeproj` is committed for convenience, but changes should still be driven from `project.yml`.

## Docs

Project docs live in `docs/`:

- `docs/PRD.md`
- `docs/PRD-REVIEW.md`
- `docs/DEV-PLAN.md`
- `docs/SYNC-TECH-DOC.md`

## Status

This branch represents the new 2.x codebase line.

It is intentionally separate from the older implementation history.
