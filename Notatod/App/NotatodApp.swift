import SwiftUI
import SwiftData

@main
struct NotatodApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var appState = AppState()
    @State private var editorSession = EditorSession()
    @State private var menubarController = MenubarController()
    @State private var settingsService = SettingsService()
    @State private var hotkeyService = HotkeyService()
    @State private var syncService = SyncService()

    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try PersistenceBootstrap.makeModelContainer()
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch appState.appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private var nsAppearance: NSAppearance? {
        switch appState.appearance {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }

    var body: some Scene {
        let panelGeometry = menubarController.panelGeometry

        MenuBarExtra("Notatod", systemImage: "note.text") {
            ContentView()
                .environment(appState)
                .environment(editorSession)
                .environment(menubarController)
                .environment(settingsService)
                .environment(syncService)
                .modelContainer(modelContainer)
                .frame(
                    minWidth: panelGeometry.minWidth,
                    idealWidth: panelGeometry.idealWidth,
                    maxWidth: panelGeometry.maxWidth,
                    minHeight: panelGeometry.minHeight,
                    idealHeight: panelGeometry.idealHeight,
                    maxHeight: panelGeometry.maxHeight
                )
                .id(appState.appearance)
                .task {
                    SyncDebugLogger.reset()
                    SyncDebugLogger.log("[NotatodApp.task] menu bar task started")
                    syncService.attach(modelContext: modelContainer.mainContext)
                    SyncDebugLogger.log("[NotatodApp.task] sync service attached")
                    let repository = NoteRepository(modelContext: modelContainer.mainContext, syncService: syncService)
                    try? repository.bootstrapIfNeeded()
                    SyncDebugLogger.log("[NotatodApp.task] bootstrap finished")
                    appState.appearance = settingsService.appearance
                    NSApp.appearance = nsAppearance
                    hotkeyService.onToggle = {
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
                .onChange(of: appState.appearance) { _, _ in
                    NSApp.appearance = nsAppearance
                }
                .preferredColorScheme(preferredColorScheme)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appState)
                .environment(menubarController)
                .environment(settingsService)
                .environment(syncService)
                .id(appState.appearance)
                .task {
                    syncService.attach(modelContext: modelContainer.mainContext)
                }
                .onAppear {
                    NSApp.appearance = nsAppearance
                }
                .onChange(of: appState.appearance) { _, _ in
                    NSApp.appearance = nsAppearance
                }
                .preferredColorScheme(preferredColorScheme)
        }
        .modelContainer(modelContainer)
    }
}
