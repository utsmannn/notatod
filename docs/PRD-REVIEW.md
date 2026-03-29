# PRD Technical Review: Notatod
## Menubar Notes Application for macOS

**Reviewed by:** Maya (Distinguished Swift Architect, former Apple Engineer)
**Review Date:** January 2026
**PRD Version:** 1.0

---

## Executive Summary

The Notatod PRD presents a well-scoped, technically feasible menubar notes application. The feature set is appropriate for a v1.0 release, and the proposed architecture aligns with modern macOS development practices. This review identifies key technical considerations, potential challenges, and recommendations for implementation.

**Overall Assessment:** APPROVED with recommendations

---

## 1. Technical Feasibility Review

### 1.1 Feature Feasibility Matrix

| Feature | Feasibility | Complexity | Notes |
|---------|-------------|------------|-------|
| Menubar Integration | Fully Feasible | Low | Standard macOS pattern |
| Popover Window | Fully Feasible | Low | NSPopover or SwiftUI popover |
| Global Hotkey | Fully Feasible | Medium | Requires CGEvent or MASShortcut |
| Multiple Notes | Fully Feasible | Low | Standard CRUD operations |
| Markdown Support | Fully Feasible | Medium | Several library options |
| Image Support | Fully Feasible | Medium-High | Storage and rendering considerations |
| Split View Editor | Fully Feasible | Medium | SwiftUI HSplitView or custom |
| Search | Fully Feasible | Low | Native SwiftUI searchable |
| Auto-save | Fully Feasible | Low | Combine debounce pattern |

### 1.2 Architecture Concerns

**Strengths of Proposed Architecture:**
- Native Swift/SwiftUI is the correct choice for a menubar app
- Local-first storage approach is appropriate
- SwiftData is the modern choice for persistence
- Universal Binary requirement is standard practice

**Concerns:**

1. **Menubar App Architecture Pattern**
   - The PRD does not specify whether this is a "pure" menubar app (no dock icon) or a hybrid
   - Recommendation: Use `LSUIElement = YES` in Info.plist for true menubar-only experience
   - Consider: Users may want a "detach to window" option for extended editing

2. **State Management**
   - With multiple notes, search, and real-time preview, state management needs careful design
   - Recommendation: Use `@Observable` (iOS 17+/macOS 14+) or `ObservableObject` pattern with clear separation

3. **Memory Constraints**
   - The 50MB memory target is aggressive if storing images inline
   - Large markdown documents with many images could exceed this
   - Recommendation: Implement lazy image loading and consider thumbnail generation

### 1.3 macOS 13.0+ Minimum - Assessment

**Appropriate Choice:** Yes, with caveats.

**Rationale:**
- macOS 13 (Ventura) provides stable SwiftUI 4.0 with mature macOS support
- `NavigationSplitView` is available (macOS 13+)
- SwiftData requires macOS 14+ (Sonoma), creating a conflict

**Conflict Identified:**
```
PRD specifies: macOS 13.0 (Ventura)
PRD specifies: SwiftData for persistence

Problem: SwiftData requires macOS 14.0 (Sonoma)
```

**Recommendations:**
1. **Option A:** Raise minimum to macOS 14.0 and use SwiftData exclusively
2. **Option B:** Keep macOS 13.0 and use Core Data with potential SwiftData migration path
3. **Option C:** Conditional compilation - SwiftData on macOS 14+, Core Data fallback on macOS 13

**My Recommendation:** Option A (macOS 14.0 minimum)
- SwiftData is significantly simpler to implement
- macOS 14 adoption is already high (as of 2026)
- Reduces maintenance burden of supporting two persistence layers
- Enables use of `@Observable` macro for cleaner state management

---

## 2. SwiftUI/macOS Implementation Considerations

### 2.1 Menubar App Implementation

**Two Approaches:**

#### Approach A: NSStatusItem + NSPopover (Recommended)
```swift
// AppDelegate.swift
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Notatod")
            button.action = #selector(togglePopover)
        }

        popover = NSPopover()
        popover?.contentViewController = NSHostingController(rootView: ContentView())
        popover?.behavior = .transient // Auto-hide on click outside
    }

    @objc func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}
```

**Pros:**
- Full control over popover behavior
- Native macOS appearance
- Reliable auto-dismiss behavior

**Cons:**
- Requires AppDelegate (not pure SwiftUI App lifecycle)
- Slightly more boilerplate

#### Approach B: MenuBarExtra (macOS 13+)
```swift
@main
struct NotatodApp: App {
    var body: some Scene {
        MenuBarExtra("Notatod", systemImage: "note.text") {
            ContentView()
        }
        .menuBarExtraStyle(.window) // Popover-style window
    }
}
```

**Pros:**
- Pure SwiftUI
- Less code
- Modern approach

**Cons:**
- Less control over window behavior
- `.window` style has sizing quirks
- Global hotkey integration is more complex

**My Recommendation:** Hybrid Approach
- Use `MenuBarExtra` with `.window` style for the main structure
- Supplement with `NSEvent.addGlobalMonitorForEvents` for global hotkey
- This gives you SwiftUI simplicity with AppKit power where needed

### 2.2 Popover vs Window

**Popover Characteristics:**
- Attached to menubar button
- Auto-dismisses on click outside (with `.transient` behavior)
- Cannot be moved or detached
- Limited resizing options
- Feels more "utility" and lightweight

**Window Characteristics:**
- Independent floating window
- Can be positioned anywhere
- Full resize support
- Persists until explicitly closed
- Feels more like a full application

**Recommendation for Notatod:** Popover with Window Option
```swift
enum WindowMode {
    case popover    // Default, attached to menubar
    case detached   // Floating window for extended editing
}
```

Users should be able to "detach" the popover into a floating window for extended editing sessions, then return to popover mode.

### 2.3 SwiftData vs Core Data

**SwiftData (Recommended if targeting macOS 14+):**
```swift
@Model
final class Note {
    var id: UUID
    var title: String
    var content: String
    var isPinned: Bool
    var createdAt: Date
    var modifiedAt: Date

    @Relationship(deleteRule: .cascade)
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

@Model
final class NoteImage {
    var id: UUID
    var filename: String
    var createdAt: Date

    init(filename: String) {
        self.id = UUID()
        self.filename = filename
        self.createdAt = Date()
    }
}
```

**Advantages:**
- Declarative model definitions
- Automatic CloudKit integration path for v2.0
- Type-safe queries with `#Predicate`
- Seamless SwiftUI integration with `@Query`

**Core Data (If supporting macOS 13):**
- More verbose but battle-tested
- Requires manual model file (.xcdatamodeld)
- Migration path to SwiftData is straightforward

### 2.4 Markdown Rendering Options

**Option 1: Native AttributedString (macOS 12+)**
```swift
func renderMarkdown(_ text: String) -> AttributedString {
    do {
        return try AttributedString(markdown: text)
    } catch {
        return AttributedString(text)
    }
}
```
- Built-in, no dependencies
- Limited feature set (no syntax highlighting, no tables)
- Good for simple markdown

**Option 2: swift-markdown (Apple's Parser)**
```swift
import Markdown

func parseMarkdown(_ text: String) -> Document {
    return Document(parsing: text)
}
```
- Official Apple package
- Provides AST for custom rendering
- Requires custom renderer for SwiftUI

**Option 3: MarkdownUI (Recommended)**
```swift
import MarkdownUI

struct MarkdownPreview: View {
    let content: String

    var body: some View {
        Markdown(content)
            .markdownTheme(.gitHub)
            .markdownCodeSyntaxHighlighter(.splash(theme: .sundellsColors(withFont: .init(size: 14))))
    }
}
```
- Full CommonMark + GFM support
- Syntax highlighting (with Splash or Highlightr)
- Tables, task lists, strikethrough
- Theming support
- Active community maintenance

**Option 4: Ink + Custom Renderer**
- Lightweight parser
- Requires custom SwiftUI rendering

**My Recommendation:** MarkdownUI
- Best balance of features and ease of implementation
- Supports all PRD requirements (code blocks, tables, task lists)
- Good performance for typical note sizes
- Syntax highlighting via Splash integration

---

## 3. Potential Challenges

### 3.1 Image Handling and Storage

**Challenge 1: Image Insertion Flow**
```
Clipboard Paste (Cmd+V)
    |
    v
Detect image data in pasteboard
    |
    v
Generate unique filename (UUID.png)
    |
    v
Save to ~/Library/Application Support/Notatod/images/
    |
    v
Insert markdown reference: ![](images/UUID.png)
    |
    v
Render inline in preview
```

**Challenge 2: Image Reference in Markdown**
- Standard markdown uses relative paths: `![alt](path/to/image.png)`
- Need custom URL scheme or base path resolution
- Consider: `notatod://images/UUID.png` custom scheme

**Challenge 3: Orphaned Images**
- When note is deleted, images become orphaned
- When image markdown is removed, file remains
- Solution: Periodic cleanup job or reference counting

**Challenge 4: Large Images**
- Users may paste high-resolution screenshots
- Impact on storage and memory
- Solution:
  - Resize on import (max 1920px width)
  - Generate thumbnails for preview
  - Store originals for export

**Recommended Image Storage Strategy:**
```swift
struct ImageManager {
    let baseURL: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Notatod/images")

    func saveImage(_ image: NSImage, quality: CGFloat = 0.85) throws -> String {
        let id = UUID().uuidString
        let filename = "\(id).jpg"
        let url = baseURL.appendingPathComponent(filename)

        // Resize if too large
        let resized = resize(image, maxWidth: 1920)

        guard let data = resized.jpegData(compressionQuality: quality) else {
            throw ImageError.conversionFailed
        }

        try data.write(to: url)
        return filename
    }
}
```

### 3.2 Performance Concerns

**Concern 1: Markdown Rendering Performance**
- Large documents with many code blocks can be slow
- Solution: Debounce preview updates (300-500ms delay)

```swift
class EditorViewModel: ObservableObject {
    @Published var content: String = ""
    @Published var renderedContent: String = ""

    private var renderCancellable: AnyCancellable?

    init() {
        renderCancellable = $content
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] newContent in
                self?.renderedContent = newContent
            }
    }
}
```

**Concern 2: Syntax Highlighting in Editor**
- Real-time syntax highlighting can be CPU-intensive
- Solution: Use NSTextView with custom TextStorage for efficient highlighting
- Consider: Limit highlighting to visible range only

**Concern 3: App Launch Time (<500ms target)**
- SwiftUI cold launch can be slow
- Solutions:
  - Keep data model lean
  - Lazy load notes list
  - Defer non-critical initialization
  - Use `@MainActor` appropriately

**Concern 4: Memory with Multiple Notes Open**
- Each note with preview = 2x memory
- Solution: Only render preview for active note

### 3.3 Edge Cases

1. **Very Long Notes**
   - Notes with 10,000+ lines
   - Solution: Virtualized text view, pagination for preview

2. **Corrupted Images**
   - Referenced image file deleted externally
   - Solution: Graceful fallback placeholder image

3. **Concurrent Edits**
   - If iCloud sync added later, conflict resolution needed
   - Solution: Design data model with sync in mind from start

4. **Encoding Issues**
   - Non-UTF8 pasted content
   - Solution: Normalize to UTF-8 on paste

5. **Popover Positioning**
   - Multiple displays, menubar on different screen
   - Solution: Test thoroughly on multi-display setups

6. **Global Hotkey Conflicts**
   - Cmd+Shift+N may conflict with other apps
   - Solution: Make hotkey customizable, detect conflicts

---

## 4. Suggestions for Improvement

### 4.1 Architecture Recommendations

**4.1.1 Add Document-Based Architecture Option**
Consider supporting the macOS document model for future compatibility:
```swift
struct Note: FileDocument {
    static var readableContentTypes: [UTType] { [.markdown] }

    var content: String

    init(content: String = "") {
        self.content = content
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        content = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = content.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}
```

**4.1.2 Implement Proper MVVM Architecture**
```
NotatodApp
    |
    +-- AppState (Singleton, environment object)
    |       |
    |       +-- notes: [Note]
    |       +-- selectedNoteID: UUID?
    |       +-- searchQuery: String
    |       +-- viewMode: ViewMode
    |
    +-- Views
    |       |
    |       +-- ContentView
    |       +-- NoteListView
    |       +-- EditorView
    |       +-- PreviewView
    |       +-- SettingsView
    |
    +-- ViewModels
    |       |
    |       +-- NoteListViewModel
    |       +-- EditorViewModel
    |
    +-- Services
            |
            +-- PersistenceService
            +-- ImageService
            +-- MarkdownService
            +-- HotkeyService
```

### 4.2 Missing Technical Considerations

**4.2.1 Accessibility**
PRD does not mention accessibility requirements. Add:
- VoiceOver support for all UI elements
- Keyboard navigation throughout app
- Dynamic Type support (respect system font size)
- High contrast mode support

**4.2.2 Localization**
No mention of i18n. Consider:
- Extract all strings to Localizable.strings
- Support RTL layouts
- Date/time formatting

**4.2.3 Error Handling**
Add user-facing error states:
- Storage full
- Permission denied (sandbox)
- Corrupted data recovery

**4.2.4 Data Export/Backup**
Expand on export functionality:
```swift
enum ExportFormat {
    case markdown       // Individual .md files
    case json           // Full database export
    case html           // Rendered HTML
    case pdf            // Print-ready
    case zip            // Archive with images
}
```

**4.2.5 Undo/Redo Architecture**
PRD mentions undo/redo. Implementation detail:
```swift
class UndoableDocument: ObservableObject {
    @Published var content: String

    private let undoManager = UndoManager()

    func updateContent(_ newContent: String) {
        let oldContent = content
        undoManager.registerUndo(withTarget: self) { target in
            target.updateContent(oldContent)
        }
        content = newContent
    }
}
```

### 4.3 Best Practices for macOS Menubar Apps

**4.3.1 Respect System Appearance**
```swift
struct ThemedView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        // Automatically adapts to system theme
    }
}
```

**4.3.2 Minimize Memory Footprint**
- Release cached images when popover closes
- Use weak references where appropriate
- Monitor with Instruments

**4.3.3 Handle System Events**
```swift
NotificationCenter.default.addObserver(
    forName: NSApplication.willSleepNotification,
    object: nil,
    queue: .main
) { _ in
    // Save all pending changes
}

NotificationCenter.default.addObserver(
    forName: NSApplication.willTerminateNotification,
    object: nil,
    queue: .main
) { _ in
    // Ensure data integrity
}
```

**4.3.4 Sandboxing Considerations**
App Store requires sandboxing:
- Use app container for data storage (already in PRD)
- Request appropriate entitlements
- Test with sandbox enabled during development

**4.3.5 Launch at Login**
Use SMAppService (modern approach, macOS 13+):
```swift
import ServiceManagement

func setLaunchAtLogin(_ enabled: Bool) {
    do {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    } catch {
        print("Failed to set launch at login: \(error)")
    }
}
```

### 4.4 Additional Feature Recommendations

**4.4.1 Quick Note from Anywhere**
Add "Quick Note" mode - global hotkey opens minimal input field:
```
+---------------------------+
| Quick Note...             |
| [Enter to save to inbox]  |
+---------------------------+
```

**4.4.2 Note Templates**
Pre-configured templates for common use cases:
- Meeting notes
- Code snippet
- Todo list
- Journal entry

**4.4.3 Spotlight Integration**
Make notes searchable via Spotlight:
```swift
import CoreSpotlight

func indexNote(_ note: Note) {
    let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
    attributeSet.title = note.title
    attributeSet.contentDescription = note.content.prefix(200).description

    let item = CSSearchableItem(
        uniqueIdentifier: note.id.uuidString,
        domainIdentifier: "com.notatod.notes",
        attributeSet: attributeSet
    )

    CSSearchableIndex.default().indexSearchableItems([item])
}
```

**4.4.4 Widgets (Future)**
WidgetKit support for note previews on desktop.

---

## 5. Recommended Technology Stack

| Component | Recommendation | Rationale |
|-----------|----------------|-----------|
| UI Framework | SwiftUI | Modern, declarative, macOS-native |
| App Lifecycle | SwiftUI App + AppDelegate | Best of both worlds |
| Persistence | SwiftData | Modern, type-safe, CloudKit-ready |
| Markdown | MarkdownUI | Full GFM support, syntax highlighting |
| Syntax Highlighting | Splash | Swift-native, performant |
| Global Hotkey | HotKey (SPM) | Well-maintained, simple API |
| State Management | @Observable + SwiftUI | Modern, efficient |
| Image Processing | AppKit/NSImage | Native, efficient |

---

## 6. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| SwiftData bugs/limitations | Medium | Medium | Thorough testing, fallback plan |
| Memory exceeds 50MB target | Medium | Low | Lazy loading, monitoring |
| Global hotkey conflicts | Low | Low | User-configurable hotkey |
| Performance with large notes | Low | Medium | Virtualization, debouncing |
| App Store rejection | Low | High | Follow HIG, proper sandboxing |

---

## 7. Conclusion

The Notatod PRD is well-conceived and technically sound. The primary technical decision needed is the minimum macOS version:

**Recommendation:** Target macOS 14.0+ (Sonoma)

This enables:
- SwiftData for clean persistence
- @Observable macro for efficient state management
- Latest SwiftUI improvements
- Reduced maintenance burden

The feature scope is appropriate for v1.0. The phased approach (menubar -> markdown -> images -> polish) is logical and manageable.

**Next Steps:**
1. Finalize minimum macOS version
2. Create Xcode project with proper bundle identifiers
3. Implement Phase 1 (core menubar app) as proof of concept
4. Validate performance targets early

---

*Review completed by Maya*
*Distinguished Swift Architect*
*Former Apple Engineer (Swift, UIKit, SwiftUI teams)*
