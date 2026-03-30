# Development Plan: Notatod
## Menubar Notes Application for macOS

**Based on:** PRD v1.0 and Maya's Technical Review
**Target:** macOS 14.0+ (Sonoma)
**Last Updated:** January 2026

---

## 1. Project Setup

### 1.1 Xcode Project Configuration

```
Project Name: Notatod
Bundle Identifier: com.notatod.app
Deployment Target: macOS 14.0
Language: Swift
UI Framework: SwiftUI
```

**Info.plist Settings:**
```xml
<key>LSUIElement</key>
<true/>  <!-- Menubar-only app, no dock icon -->

<key>LSApplicationCategoryType</key>
<string>public.app-category.productivity</string>
```

### 1.2 Entitlements

```xml
<!-- Notatod.entitlements -->
<key>com.apple.security.app-sandbox</key>
<true/>

<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

### 1.3 SPM Dependencies

```swift
// Package.swift dependencies
dependencies: [
    .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.3.0"),
    .package(url: "https://github.com/soffes/HotKey", from: "0.2.0"),
    .package(url: "https://github.com/JohnSundell/Splash", from: "0.16.0")
]
```

| Package | Version | Purpose |
|---------|---------|---------|
| MarkdownUI | 2.3.0+ | Markdown rendering with GFM support |
| HotKey | 0.2.0+ | Global keyboard shortcut handling |
| Splash | 0.16.0+ | Syntax highlighting for code blocks |

### 1.4 Project Folder Structure

```
Notatod/
├── NotatodApp.swift              # App entry point
├── AppDelegate.swift             # AppKit integration
│
├── Models/
│   ├── Note.swift                # SwiftData Note model
│   └── NoteImage.swift           # SwiftData NoteImage model
│
├── Views/
│   ├── ContentView.swift         # Main container view
│   ├── NoteListView.swift        # Sidebar with note list
│   ├── NoteRowView.swift         # Individual note row
│   ├── EditorView.swift          # Markdown text editor
│   ├── PreviewView.swift         # Markdown preview
│   ├── SplitEditorView.swift     # Split edit/preview
│   ├── SettingsView.swift        # Settings panel
│   └── SearchBarView.swift       # Search input
│
├── ViewModels/
│   ├── AppState.swift            # Global app state
│   ├── NoteListViewModel.swift   # Note list logic
│   └── EditorViewModel.swift     # Editor logic with debounce
│
├── Services/
│   ├── PersistenceService.swift  # SwiftData operations
│   ├── ImageService.swift        # Image handling
│   ├── HotkeyService.swift       # Global hotkey
│   └── SettingsService.swift     # UserDefaults wrapper
│
├── Utilities/
│   ├── Constants.swift           # App constants
│   └── Extensions.swift          # Swift extensions
│
├── Resources/
│   └── Assets.xcassets           # App icons, colors
│
└── Preview Content/
    └── PreviewData.swift         # SwiftUI preview data
```

---

## 2. Phase 1: Core Menubar App

### 2.1 Tasks

- [ ] **1.1** Create new Xcode project with SwiftUI App lifecycle
- [ ] **1.2** Configure Info.plist for menubar-only app (LSUIElement)
- [ ] **1.3** Implement MenuBarExtra with window style
- [ ] **1.4** Create basic ContentView with placeholder content
- [ ] **1.5** Add AppDelegate for additional AppKit control
- [ ] **1.6** Configure app icon for menubar (SF Symbol: note.text)
- [ ] **1.7** Implement popover auto-dismiss on focus loss
- [ ] **1.8** Test on both Apple Silicon and Intel Macs

### 2.2 Implementation Details

**NotatodApp.swift:**
```swift
import SwiftUI
import SwiftData

@main
struct NotatodApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Note.self, NoteImage.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        MenuBarExtra("Notatod", systemImage: "note.text") {
            ContentView()
                .modelContainer(sharedModelContainer)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
```

**AppDelegate.swift:**
```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Additional setup if needed
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup and ensure data saved
    }
}
```

### 2.3 Acceptance Criteria

- App appears only in menubar (no dock icon)
- Clicking menubar icon opens popover window
- Clicking outside dismisses popover
- App launches in < 500ms

---

## 3. Phase 2: Notes Management

### 3.1 Tasks

- [ ] **2.1** Define SwiftData models (Note, NoteImage)
- [ ] **2.2** Create PersistenceService for CRUD operations
- [ ] **2.3** Implement NoteListView sidebar
- [ ] **2.4** Create NoteRowView for list items
- [ ] **2.5** Add "New Note" functionality (+button)
- [ ] **2.6** Implement note deletion (swipe/right-click)
- [ ] **2.7** Add inline title editing
- [ ] **2.8** Implement search/filter functionality
- [ ] **2.9** Add pinned notes feature
- [ ] **2.10** Create welcome note on first launch

### 3.2 Implementation Details

**Note.swift:**
```swift
import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID
    var title: String
    var content: String
    var isPinned: Bool
    var createdAt: Date
    var modifiedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \NoteImage.note)
    var images: [NoteImage]

    init(title: String = "Untitled", content: String = "") {
        self.id = UUID()
        self.title = title
        self.content = content
        self.isPinned = false
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.images = []
    }
}
```

**NoteImage.swift:**
```swift
import Foundation
import SwiftData

@Model
final class NoteImage {
    var id: UUID
    var filename: String
    var createdAt: Date

    var note: Note?

    init(filename: String) {
        self.id = UUID()
        self.filename = filename
        self.createdAt = Date()
    }
}
```

### 3.3 Acceptance Criteria

- Can create, read, update, delete notes
- Notes persist across app restarts
- Search filters notes by title and content
- Pinned notes appear at top of list
- Deleting note also deletes associated images

---

## 4. Phase 3: Markdown Editor

### 4.1 Tasks

- [ ] **3.1** Create EditorView with TextEditor
- [ ] **3.2** Implement PreviewView with MarkdownUI
- [ ] **3.3** Create SplitEditorView (HSplitView)
- [ ] **3.4** Add view mode toggle (Edit/Preview/Split)
- [ ] **3.5** Implement auto-save with debouncing (300ms)
- [ ] **3.6** Add syntax highlighting in editor (basic)
- [ ] **3.7** Configure MarkdownUI theme to match system appearance
- [ ] **3.8** Add syntax highlighting for code blocks (Splash)
- [ ] **3.9** Implement undo/redo functionality
- [ ] **3.10** Add "last saved" indicator

### 4.2 Implementation Details

**EditorViewModel.swift:**
```swift
import SwiftUI
import Combine

@Observable
class EditorViewModel {
    var content: String = ""
    var lastSaved: Date?

    private var saveSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()
    private let persistenceService: PersistenceService
    private var currentNote: Note?

    init(persistenceService: PersistenceService) {
        self.persistenceService = persistenceService

        // Debounced auto-save
        saveSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] newContent in
                self?.performSave(content: newContent)
            }
            .store(in: &cancellables)
    }

    func contentDidChange(_ newContent: String) {
        content = newContent
        saveSubject.send(newContent)
    }

    private func performSave(content: String) {
        guard let note = currentNote else { return }
        note.content = content
        note.modifiedAt = Date()
        lastSaved = Date()
    }
}
```

**PreviewView.swift:**
```swift
import SwiftUI
import MarkdownUI

struct PreviewView: View {
    let content: String

    var body: some View {
        ScrollView {
            Markdown(content)
                .markdownTheme(.gitHub)
                .padding()
        }
    }
}
```

### 4.3 Acceptance Criteria

- Markdown renders correctly in preview
- Code blocks have syntax highlighting
- Auto-save triggers 300ms after typing stops
- Split view shows editor and preview side-by-side
- Toggle between Edit, Preview, and Split modes

---

## 5. Phase 4: Image Support

### 5.1 Tasks

- [ ] **4.1** Create ImageService for image handling
- [ ] **4.2** Set up images directory in Application Support
- [ ] **4.3** Implement clipboard paste detection (Cmd+V)
- [ ] **4.4** Handle drag & drop images into editor
- [ ] **4.5** Save images with UUID filenames
- [ ] **4.6** Resize large images on import (max 1920px)
- [ ] **4.7** Insert markdown image reference into editor
- [ ] **4.8** Render images in preview using custom URL scheme
- [ ] **4.9** Implement orphaned image cleanup
- [ ] **4.10** Add click-to-view-fullsize for images

### 5.2 Implementation Details

**ImageService.swift:**
```swift
import AppKit
import Foundation

actor ImageService {
    static let shared = ImageService()

    private let imagesDirectory: URL
    private let maxImageWidth: CGFloat = 1920

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        imagesDirectory = appSupport
            .appendingPathComponent("Notatod", isDirectory: true)
            .appendingPathComponent("images", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: imagesDirectory,
            withIntermediateDirectories: true
        )
    }

    func saveImage(_ image: NSImage) async throws -> String {
        let id = UUID().uuidString
        let filename = "\(id).jpg"
        let url = imagesDirectory.appendingPathComponent(filename)

        // Resize if needed
        let resized = resize(image, maxWidth: maxImageWidth)

        guard let data = resized.jpegData(compressionQuality: 0.85) else {
            throw ImageError.conversionFailed
        }

        try data.write(to: url)
        return filename
    }

    func loadImage(filename: String) async -> NSImage? {
        let url = imagesDirectory.appendingPathComponent(filename)
        return NSImage(contentsOf: url)
    }

    func deleteImage(filename: String) async throws {
        let url = imagesDirectory.appendingPathComponent(filename)
        try FileManager.default.removeItem(at: url)
    }

    private func resize(_ image: NSImage, maxWidth: CGFloat) -> NSImage {
        guard image.size.width > maxWidth else { return image }

        let ratio = maxWidth / image.size.width
        let newSize = NSSize(
            width: image.size.width * ratio,
            height: image.size.height * ratio
        )

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()

        return newImage
    }
}

enum ImageError: Error {
    case conversionFailed
    case saveFailed
}

extension NSImage {
    func jpegData(compressionQuality: CGFloat) -> Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: compressionQuality]
        )
    }
}
```

### 5.3 Acceptance Criteria

- Cmd+V pastes image from clipboard
- Drag & drop images into editor works
- Images stored in Application Support directory
- Large images automatically resized
- Images render in markdown preview
- Deleting note cleans up associated images

---

## 6. Phase 5: Polish & Settings

### 6.1 Tasks

- [ ] **5.1** Create SettingsView with all options
- [ ] **5.2** Implement global hotkey (Cmd+Shift+N default)
- [ ] **5.3** Add customizable hotkey setting
- [ ] **5.4** Implement Launch at Login (SMAppService)
- [ ] **5.5** Add appearance setting (Light/Dark/System)
- [ ] **5.6** Add editor font size setting
- [ ] **5.7** Add default view mode setting
- [ ] **5.8** Implement all keyboard shortcuts
- [ ] **5.9** Add "About" panel
- [ ] **5.10** Final polish and animations

### 6.2 Implementation Details

**HotkeyService.swift:**
```swift
import HotKey
import AppKit

@Observable
class HotkeyService {
    private var hotKey: HotKey?
    var onToggle: (() -> Void)?

    init() {
        setupDefaultHotkey()
    }

    func setupDefaultHotkey() {
        // Cmd+Shift+N
        hotKey = HotKey(key: .n, modifiers: [.command, .shift])
        hotKey?.keyDownHandler = { [weak self] in
            self?.onToggle?()
        }
    }

    func updateHotkey(key: Key, modifiers: NSEvent.ModifierFlags) {
        hotKey = HotKey(key: key, modifiers: modifiers)
        hotKey?.keyDownHandler = { [weak self] in
            self?.onToggle?()
        }
    }
}
```

**SettingsService.swift:**
```swift
import SwiftUI
import ServiceManagement

@Observable
class SettingsService {
    @AppStorage("appearance") var appearance: AppAppearance = .system
    @AppStorage("editorFontSize") var editorFontSize: Double = 14
    @AppStorage("defaultViewMode") var defaultViewMode: ViewMode = .split
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false {
        didSet {
            updateLaunchAtLogin()
        }
    }

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }
}

enum AppAppearance: String, CaseIterable {
    case light, dark, system
}

enum ViewMode: String, CaseIterable {
    case edit, preview, split
}
```

### 6.3 Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Toggle app | Cmd+Shift+N (global) |
| New note | Cmd+N |
| Delete note | Cmd+Backspace |
| Search | Cmd+F |
| Toggle preview | Cmd+P |
| Settings | Cmd+, |

### 6.4 Acceptance Criteria

- Global hotkey opens/closes app from anywhere
- Settings persist across restarts
- Launch at Login works correctly
- All keyboard shortcuts functional
- Appearance follows system/user preference

---

## 7. Testing Strategy

### 7.1 Unit Tests

```
NotatodTests/
├── Models/
│   ├── NoteTests.swift
│   └── NoteImageTests.swift
│
├── Services/
│   ├── PersistenceServiceTests.swift
│   ├── ImageServiceTests.swift
│   └── SettingsServiceTests.swift
│
└── ViewModels/
    ├── NoteListViewModelTests.swift
    └── EditorViewModelTests.swift
```

**Test Coverage Targets:**
- Models: 100%
- Services: 90%
- ViewModels: 85%

### 7.2 Performance Tests

- [ ] App launch time < 500ms
- [ ] Note switching < 100ms
- [ ] Memory usage < 50MB idle
- [ ] Markdown render < 100ms for 1000-line document

### 7.3 Manual Testing Checklist

- [ ] Test on macOS 14.0, 14.1, 15.0
- [ ] Test on Apple Silicon and Intel
- [ ] Test with multiple displays
- [ ] Test with different system appearances
- [ ] Test with accessibility features (VoiceOver)
- [ ] Test keyboard-only navigation
- [ ] Test with very large notes (10,000+ lines)
- [ ] Test with many images
- [ ] Test memory under extended use

---

## 8. Definition of Done

Each phase is complete when:

1. All tasks are checked off
2. All acceptance criteria pass
3. Unit tests written and passing
4. No memory leaks (Instruments)
5. No compiler warnings
6. Code reviewed

---

*Development Plan v1.0*
*Based on Maya's Technical Review*
