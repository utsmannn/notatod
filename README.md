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
- `GOOGLE_REDIRECT_URI`
- `GOOGLE_CLIENT_SECRET` (optional for native desktop OAuth with PKCE; leave it empty unless your Google OAuth client explicitly requires it)

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
- Release versioning also starts from `project.yml`; `scripts/release-version.sh` updates `project.yml` and keeps `Notatod/Info.plist` in sync before regenerating the project.

## Release workflow

Releases are intentionally manual.

### Requirements

- The workflow is `workflow_dispatch` only.
- It must be started from the `main` branch.
- The repository should define a protected GitHub Environment named `release` so publish-capable steps require approval.
- The self-hosted runner must match the workflow labels `self-hosted`, `macOS`, and `X64`.
- `xcodegen`, `xcodebuild`, `gh`, and `hdiutil` must be available on the release runner.

### How it works

1. Manually trigger `.github/workflows/release.yml` and choose `major`, `minor`, or `patch`.
2. The workflow hard-fails unless it runs on `refs/heads/main` for `utsmannn/notatod` and is started by a human actor.
3. The workflow fetches tags first, then `scripts/release-version.sh` computes the next version from the latest existing `vX.Y.Z` tag (or `project.yml` if no tag is newer), increments the build number, and syncs `Notatod/Info.plist`.
4. `xcodegen generate` regenerates `Notatod.xcodeproj`.
5. The workflow verifies the diff is limited to release metadata, then runs:
   - `xcodebuild build -scheme Notatod -project Notatod.xcodeproj -configuration Release -derivedDataPath "$BUILD_DIR/DerivedData"`
   - `xcodebuild test -scheme Notatod -project Notatod.xcodeproj -only-testing:NotatodTests`
6. If both pass, it packages `Notatod.app` into `dist/Notatod-vX.Y.Z.dmg`, commits the version bump, creates an annotated `vX.Y.Z` tag, pushes `main` and the tag, and publishes a GitHub Release with generated notes plus the DMG asset.

### Local verification

You can dry-run version calculations without writing files:

```bash
./scripts/release-version.sh patch
./scripts/release-version.sh minor
./scripts/release-version.sh major
```

Apply a bump locally with:

```bash
./scripts/release-version.sh patch --write
xcodegen generate
```

## Docs

Project docs live in `docs/`:

- `docs/PRD.md`
- `docs/PRD-REVIEW.md`
- `docs/DEV-PLAN.md`
- `docs/SYNC-TECH-DOC.md`

## Status

This branch represents the new 2.x codebase line.

It is intentionally separate from the older implementation history.
