# Product Requirements Document (PRD)
# Notatod - Menubar Notes for macOS

## 1. Product Overview

### 1.1 Product Name
**Notatod** - A lightweight, always-accessible notes application that lives in your macOS menubar.

### 1.2 Vision Statement
Notatod provides instant access to your notes without interrupting your workflow. Click the menubar icon, jot down your thoughts, and get back to work - all in seconds.

### 1.3 Target Users
- Developers who need quick code snippets and documentation notes
- Writers who capture ideas on the fly
- Professionals who need quick access to reference materials
- Anyone who values minimal, non-intrusive note-taking

---

## 2. Core Features

### 2.1 Menubar Integration
- **Persistent menubar icon** - Always visible for instant access
- **Popover window** - Click to reveal notes panel
- **Keyboard shortcut** - Global hotkey (Cmd+Shift+N) to toggle
- **Auto-hide** - Click outside to dismiss

### 2.2 Multiple Notes Management
- **Note list sidebar** - View all notes at a glance
- **Create new notes** - Quick "+" button
- **Delete notes** - Swipe or right-click to delete
- **Rename notes** - Inline title editing
- **Search notes** - Filter notes by title or content
- **Pin notes** - Keep important notes at top

### 2.3 Markdown Support
Full markdown syntax support including:
- **Headers** (H1-H6)
- **Bold, italic, strikethrough**
- **Code blocks** (inline and fenced with syntax highlighting)
- **Lists** (ordered and unordered)
- **Blockquotes**
- **Links**
- **Tables**
- **Checkboxes/Task lists**

### 2.4 Image Support
- **Paste images** - Cmd+V to paste from clipboard
- **Drag & drop** - Drop images directly into notes
- **Image storage** - Store images in app's data directory
- **Image preview** - Display images inline in markdown preview
- **Resize images** - Click to view full size

### 2.5 Editor Features
- **Split view** - Edit markdown on left, preview on right
- **Toggle preview** - Switch between edit-only, preview-only, or split
- **Syntax highlighting** - Markdown syntax colored in editor
- **Auto-save** - Changes saved automatically
- **Undo/Redo** - Full edit history

---

## 3. User Interface

### 3.1 Menubar Icon
- Minimal, monochrome icon (matches macOS style)
- Indicates active/new notes with subtle badge

### 3.2 Popover Window
```
┌─────────────────────────────────────────────────────┐
│ [🔍 Search...                    ] [+] [⚙️]         │
├──────────────┬──────────────────────────────────────┤
│ 📌 Pinned    │                                      │
│  └ API Keys  │  # Welcome to Notatod               │
│              │                                      │
│ 📝 Notes     │  Your notes, always accessible.     │
│  └ Ideas     │                                      │
│  └ Snippets  │  ## Features                        │
│  └ Todo      │  - Markdown support                 │
│              │  - Image embedding                  │
│              │  - Always in your menubar           │
│              │                                      │
├──────────────┴──────────────────────────────────────┤
│ [Edit] [Preview] [Split]           Last saved: now  │
└─────────────────────────────────────────────────────┘
```

### 3.3 Window Dimensions
- Default: 600x400 pixels
- Resizable with constraints (min: 400x300, max: 800x600)
- Remember last used size

---

## 4. Technical Requirements

### 4.1 Platform
- macOS 13.0 (Ventura) or later
- Native Swift/SwiftUI implementation
- Apple Silicon and Intel support (Universal Binary)

### 4.2 Data Storage
- Local storage using SwiftData (or Core Data fallback)
- Notes stored in `~/Library/Application Support/Notatod/`
- Images stored in `~/Library/Application Support/Notatod/images/`
- Export/Import as JSON or Markdown files

### 4.3 Performance
- App launch: < 500ms
- Note switching: < 100ms
- Memory footprint: < 50MB idle
- No background CPU usage when hidden

---

## 5. User Experience

### 5.1 First Launch
1. App installs to menubar automatically
2. Welcome note explains basic features
3. Brief tutorial overlay (dismissable)

### 5.2 Keyboard Shortcuts
| Action | Shortcut |
|--------|----------|
| Toggle app | Cmd+Shift+N |
| New note | Cmd+N |
| Delete note | Cmd+Backspace |
| Search | Cmd+F |
| Toggle preview | Cmd+P |
| Save (force) | Cmd+S |
| Settings | Cmd+, |

### 5.3 Settings
- **Appearance**: Light/Dark/System
- **Editor font**: Font family and size
- **Global hotkey**: Customizable
- **Launch at login**: Toggle
- **Default view**: Edit/Preview/Split

---

## 6. Future Considerations (v2.0+)

- iCloud sync across devices
- Note folders/categories
- Note sharing/export
- Rich text formatting toolbar
- Code snippet execution
- Note templates
- Note encryption/password protection

---

## 7. Success Metrics

- App launch time < 500ms
- Zero data loss (robust auto-save)
- Memory usage < 50MB
- User retention: Daily active usage
- Crash-free rate: > 99.9%

---

## 8. Timeline

| Phase | Milestone |
|-------|-----------|
| Phase 1 | Core menubar app with basic notes |
| Phase 2 | Markdown support with preview |
| Phase 3 | Image support |
| Phase 4 | Polish, settings, keyboard shortcuts |

---

*Document Version: 1.0*
*Last Updated: January 2026*
