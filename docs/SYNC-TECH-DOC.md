# Notatod Sync — Technical Document

> Google Drive API + Client-side Encryption

## 1. Overview

Notatod Sync menyimpan notes sebagai encrypted files di Google Drive user masing-masing. Zero backend, zero server cost. Data sepenuhnya milik user — bahkan Google tidak bisa membaca isi notes karena dienkripsi di client sebelum upload.

### Prinsip

- **Zero Trust** — Semua data dienkripsi sebelum meninggalkan device
- **Zero Backend** — Google Drive adalah satu-satunya storage, tidak ada server kita
- **Offline First** — App tetap berfungsi penuh tanpa internet, sync saat online
- **Piggyback Autosave** — Sync terjadi otomatis setelah autosave, bukan mekanisme terpisah

## 2. Arsitektur

```
┌─────────────────────────────────────────────────────────┐
│ Notatod App (macOS)                                     │
│                                                         │
│  EditorSession                                          │
│  ┌──────────┐   300ms    ┌──────────┐                   │
│  │ User     │  debounce  │ Autosave │                   │
│  │ typing   │ ─────────> │ trigger  │                   │
│  └──────────┘            └────┬─────┘                   │
│                               │                         │
│                    ┌──────────▼──────────┐              │
│                    │ NoteRepository.save │              │
│                    │ (SwiftData local)   │              │
│                    └──────────┬──────────┘              │
│                               │                         │
│                    ┌──────────▼──────────┐              │
│                    │ SyncEngine          │              │
│                    │ (debounce 2s)       │              │
│                    └──────────┬──────────┘              │
│                               │                         │
│              ┌────────────────▼────────────────┐        │
│              │ CryptoService                   │        │
│              │ AES-256-GCM encrypt             │        │
│              │ Key ← PBKDF2(password, salt)    │        │
│              └────────────────┬────────────────┘        │
│                               │                         │
│              ┌────────────────▼────────────────┐        │
│              │ GoogleDriveService              │        │
│              │ Upload encrypted blob           │        │
│              └────────────────┬────────────────┘        │
│                               │                         │
└───────────────────────────────┼─────────────────────────┘
                                │ HTTPS
                    ┌───────────▼───────────┐
                    │ Google Drive API       │
                    │ (user's own account)   │
                    │                        │
                    │ My Drive/              │
                    │ └── .notatod/          │
                    │     ├── manifest.enc   │
                    │     ├── <uuid>.enc     │
                    │     └── <uuid>.enc     │
                    └───────────────────────┘
```

## 3. Auto-Sync Mechanism

### 3.1 Sync Piggyback pada Autosave

Saat ini EditorSession sudah punya autosave pipeline:

```
User typing → debounce 300ms → onAutosave() → NoteRepository.save()
```

Sync ditambahkan sebagai **layer setelah local save**, dengan debounce terpisah yang lebih panjang:

```
User typing
    │
    ▼ (300ms debounce — existing)
NoteRepository.save() ← local save, instant
    │
    ▼ (enqueue to SyncEngine)
SyncEngine.enqueue(noteID)
    │
    ▼ (2s debounce — coalesce rapid saves)
SyncEngine.flush()
    │
    ▼ (encrypt → upload, background thread)
GoogleDriveService.upload()
```

### 3.2 Kenapa 2 Layer Debounce?

| Layer | Delay | Tujuan |
|-------|-------|--------|
| Autosave (existing) | 300ms | Local save cepat, prevent data loss |
| Sync debounce | 2s | Coalesce rapid edits, kurangi API calls |

User ngetik cepat selama 10 detik:
- Local save terjadi berkali-kali (setiap 300ms pause)
- Upload ke Drive **hanya 1x** (2s setelah typing berhenti)

### 3.3 Sync Queue & Batch Upload

```swift
// SyncEngine maintains a dirty set, not a queue
// Jadi kalau note A di-edit 5x dalam 2 detik, cuma 1 upload

dirtyNoteIDs: Set<UUID> = []

func enqueue(_ noteID: UUID) {
    dirtyNoteIDs.insert(noteID)
    resetDebounceTimer(2.0)  // restart 2s timer
}

func flush() {
    let batch = dirtyNoteIDs
    dirtyNoteIDs.removeAll()

    for noteID in batch {
        // encrypt + upload in background
    }
    // update manifest last
}
```

### 3.4 Sync States

```
┌─────────┐    login     ┌──────────┐   healthy   ┌────────┐
│ Offline │ ──────────> │ Syncing  │ ──────────> │ Synced │
│         │ <────────── │          │ <────────── │        │
└─────────┘   no network └──────────┘   new edit   └────────┘
                              │
                              │ error
                              ▼
                         ┌─────────┐
                         │ Error   │ ── retry (exponential backoff)
                         └─────────┘
```

Status ditampilkan di UI (footer bar existing):

| State | Display |
|-------|---------|
| Not logged in | "Google Drive: Not connected" |
| Synced | "Synced ✓" |
| Syncing | "Syncing…" |
| Offline | "Offline — changes saved locally" |
| Error | "Sync error — tap to retry" |

### 3.5 Conflict Resolution

Strategy: **Last-Write-Wins (LWW)** berdasarkan `modifiedAt` timestamp.

```
Device A edit note jam 14:00 → upload
Device B edit note jam 14:01 → upload (overwrites A's version)
Device A pull → gets B's version (newer modifiedAt)
```

Untuk MVP ini cukup. Merge-level conflict resolution terlalu complex untuk notes app.

### 3.6 Pull / Download Sync

```
App launch
    │
    ▼
Check manifest.enc di Drive
    │
    ▼ (compare with local manifest)
Download notes yang remoteModifiedAt > localModifiedAt
    │
    ▼ (decrypt → update SwiftData)
Local state updated
```

Periodic pull setiap **60 detik** saat app active (polling). Google Drive API tidak support real-time push notifications tanpa backend.

## 4. Encryption

### 4.1 Key Derivation

```
User password: "my-secret-password"
         │
         ▼
    PBKDF2-SHA256
    iterations: 600_000
    salt: random 32 bytes (stored in Drive, unencrypted)
         │
         ▼
    256-bit encryption key
    (stored in macOS Keychain, never leaves device)
```

### 4.2 Encryption per Note

```
Plaintext note (JSON):
{
    "id": "550e8400-...",
    "title": "Shopping List",
    "content": "# Shopping\n- Milk\n- Eggs",
    "isPinned": true,
    "createdAt": "2026-03-29T10:00:00Z",
    "modifiedAt": "2026-03-29T14:30:00Z"
}
    │
    ▼ AES-256-GCM (unique nonce per encryption)

Encrypted blob: [12-byte nonce][ciphertext][16-byte auth tag]
    │
    ▼ Upload as <uuid>.enc
```

### 4.3 Manifest File

`manifest.enc` adalah encrypted index of all notes (metadata saja, bukan content):

```json
{
    "version": 1,
    "salt": "base64-encoded-salt",
    "notes": {
        "550e8400-...": {
            "modifiedAt": "2026-03-29T14:30:00Z",
            "driveFileId": "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs"
        },
        "7c9e1a22-...": {
            "modifiedAt": "2026-03-28T09:00:00Z",
            "driveFileId": "0B7EVK8r0v71pOXBhSUdJWnA3dDA"
        }
    }
}
```

> `salt` disimpan unencrypted di dalam manifest plaintext wrapper. Manifest content (notes index) tetap encrypted.

Actual file format manifest:

```
[32-byte salt][12-byte nonce][encrypted JSON][16-byte auth tag]
```

### 4.4 Image Encryption

Images juga dienkripsi sebelum upload:

```
Local image file (JPEG)
    │
    ▼ AES-256-GCM

<uuid>.img.enc di Google Drive
```

Manifest menyimpan mapping `NoteImage.filename → driveFileId`.

## 5. Google OAuth2

### 5.1 Setup

- Google Cloud Console project (gratis)
- Enable Google Drive API
- OAuth2 consent screen (External, testing mode — max 100 users tanpa review)
- OAuth2 Client ID (macOS/Desktop type)

### 5.2 Auth Flow

```
User klik "Login with Google"
    │
    ▼
ASWebAuthenticationSession (atau loopback localhost:PORT)
    │
    ▼ browser opens
Google OAuth2 consent screen
    │
    ▼ user approves
Redirect dengan authorization code
    │
    ▼
Exchange code → access_token + refresh_token
    │
    ▼
Store tokens di macOS Keychain
```

### 5.3 Scopes

```
https://www.googleapis.com/auth/drive.file
```

Scope `drive.file` — app hanya bisa akses files yang **dia buat sendiri**. Tidak bisa baca file lain di Drive user. Paling restrictive dan privacy-friendly.

### 5.4 Token Management

| Token | Lifetime | Storage |
|-------|----------|---------|
| Access Token | 1 jam | Memory (re-fetch dari refresh token) |
| Refresh Token | Indefinite | macOS Keychain |
| Encryption Key | Derived | macOS Keychain |

Auto-refresh: kalau API return 401, pakai refresh token untuk dapat access token baru. Kalau refresh token juga expired/revoked → prompt user login ulang.

## 6. Google Drive File Structure

```
My Drive/
└── .notatod/                          ← hidden folder (dot prefix)
    ├── manifest.enc                   ← encrypted notes index
    ├── 550e8400-e29b-41d4.enc         ← encrypted note
    ├── 7c9e1a22-bfc0-4a3d.enc         ← encrypted note
    ├── a3bf9d01-12ef-9c8a.enc         ← encrypted note
    └── images/
        ├── img-82a1f3c0.img.enc       ← encrypted image
        └── img-d4e5f6a7.img.enc       ← encrypted image
```

## 7. Sync Operations Detail

### 7.1 Full Sync (App Launch)

```
1. Download manifest.enc dari Drive
2. Decrypt manifest
3. Compare setiap note:
   - Remote ada, Local tidak ada → download + decrypt + insert SwiftData
   - Local ada, Remote tidak ada → encrypt + upload + update manifest
   - Both exist, remote newer    → download + decrypt + update SwiftData
   - Both exist, local newer     → encrypt + upload + update manifest
   - Both exist, same modifiedAt → skip
4. Upload updated manifest.enc
```

### 7.2 Incremental Sync (After Autosave)

```
1. Encrypt changed note
2. Upload encrypted blob (create or update)
3. Update manifest entry in memory
4. Upload manifest.enc
```

### 7.3 Delete Sync

```
1. User delete note locally
2. Remove from local SwiftData
3. Delete <uuid>.enc dari Drive
4. Delete associated images dari Drive
5. Remove entry dari manifest
6. Upload updated manifest.enc
```

### 7.4 Offline Queue

Saat offline, operations di-queue:

```swift
struct PendingOperation {
    let type: OperationType  // .upload, .delete, .downloadManifest
    let noteID: UUID
    let timestamp: Date
}

enum OperationType {
    case upload
    case delete
    case downloadManifest
}
```

Saat online kembali (NWPathMonitor detect connectivity):
1. Flush pending operations in order
2. Re-download manifest untuk check remote changes
3. Resolve conflicts (LWW)

## 8. Module / File Structure

```
Notatod/
├── Services/
│   ├── Sync/
│   │   ├── SyncEngine.swift           ← Orchestrator: debounce, queue, state
│   │   ├── SyncState.swift            ← Observable sync status for UI
│   │   ├── GoogleAuthService.swift    ← OAuth2 login, token refresh
│   │   ├── GoogleDriveService.swift   ← Drive API CRUD (upload, download, delete)
│   │   ├── CryptoService.swift        ← AES-256-GCM encrypt/decrypt, PBKDF2
│   │   ├── ManifestService.swift      ← Manifest read/write/merge
│   │   └── NetworkMonitor.swift       ← NWPathMonitor wrapper
│   └── ... (existing services)
├── Views/
│   ├── Settings/
│   │   └── SyncSettingsView.swift     ← Google login, encryption password, status
│   └── ... (existing views)
└── ... (existing structure)
```

## 9. Dependencies

| Dependency | Tujuan | Catatan |
|------------|--------|---------|
| `CryptoKit` | AES-256-GCM, PBKDF2-SHA256 | Apple framework, sudah built-in |
| `AuthenticationServices` | OAuth2 browser flow | Apple framework, built-in |
| `Network` | NWPathMonitor (connectivity) | Apple framework, built-in |
| `KeychainAccess` (SPM) | Keychain wrapper | Atau pakai Security framework langsung |

> Semua crypto pakai Apple CryptoKit — no third-party crypto library. Google Drive API diakses via raw URLSession (no Google SDK needed).

## 10. Implementation Phases

### Phase 1 — Foundation (CryptoService + GoogleAuth)

- [ ] `CryptoService` — encrypt/decrypt, key derivation, salt generation
- [ ] `GoogleAuthService` — OAuth2 flow, token storage di Keychain
- [ ] `GoogleDriveService` — basic CRUD (upload file, download file, delete file, create folder)
- [ ] Unit tests untuk crypto (round-trip encrypt/decrypt)

### Phase 2 — Core Sync

- [ ] `ManifestService` — serialize/deserialize, merge logic
- [ ] `SyncEngine` — debounce timer, dirty set, flush pipeline
- [ ] `NetworkMonitor` — connectivity detection
- [ ] `SyncState` — observable state untuk UI
- [ ] Hook SyncEngine ke existing autosave pipeline di `ContentView`

### Phase 3 — UI + Settings

- [ ] `SyncSettingsView` — Google login button, encryption password setup, sync status
- [ ] Sync status di footer bar (SplitEditorView)
- [ ] First-launch setup flow (login + set password)
- [ ] "Force sync" manual button

### Phase 4 — Image Sync + Polish

- [ ] Image encrypt + upload saat paste/drop
- [ ] Image download + decrypt saat pull
- [ ] Offline queue + retry
- [ ] Exponential backoff on errors
- [ ] Edge cases: large files, rate limiting, token expiry mid-sync

## 11. Sync Settings UI

```
Settings > Sync
┌──────────────────────────────────────────────┐
│ Google Drive Sync                            │
│                                              │
│ Status: ● Synced                             │
│ Account: user@gmail.com        [Disconnect]  │
│                                              │
│ Encryption: ● Active                         │
│ [Change Password]                            │
│                                              │
│ Last synced: 2 minutes ago                   │
│ [Sync Now]                                   │
│                                              │
│ ───────────────────────────                  │
│ ⚠ Encryption password tidak bisa di-recover. │
│ Kalau lupa, data di Drive tidak bisa dibaca. │
└──────────────────────────────────────────────┘
```

## 12. Security Considerations

| Threat | Mitigation |
|--------|------------|
| Google reads notes | AES-256-GCM encryption sebelum upload |
| Man-in-the-middle | HTTPS (enforced oleh Google API) |
| Password brute-force | PBKDF2 600K iterations + random salt |
| Key leakage | Key hanya di Keychain, never written to disk |
| Stolen device | macOS Keychain protected by system password |
| Lost encryption password | **Data hilang** — by design, no recovery |
| Replay attack | Unique nonce per encryption operation |
| Tampered ciphertext | GCM auth tag verification |

## 13. API Rate Limits

Google Drive API free quota:

| Limit | Value |
|-------|-------|
| Queries per day | 1,000,000,000 |
| Queries per 100 seconds per user | 100 |
| File upload per user | 750 GB/day |

Untuk notes app, ini **lebih dari cukup**. Worst case: 100 syncs per 100 seconds = 1 sync/second, jauh di atas kebutuhan kita (1 sync per beberapa detik editing).

## 14. Migration Strategy

Existing notes di SwiftData tetap sebagai source of truth. Saat user pertama kali enable sync:

1. User login Google + set encryption password
2. App check Drive — folder `.notatod` belum ada → create
3. Upload semua existing local notes (encrypted) ke Drive
4. Create manifest.enc
5. Selesai — selanjutnya incremental sync

Kalau user punya notes di Drive dari device lain:
1. Download manifest
2. Merge: local-only notes di-upload, remote-only notes di-download, conflicts → LWW
