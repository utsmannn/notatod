import AppKit
import Observation

@MainActor
@Observable
final class MenubarController {
    private(set) weak var statusItemButton: NSStatusBarButton?

    func bindStatusItemButton(_ button: NSStatusBarButton?) {
        statusItemButton = button
    }

    func revealEditorPanel() {
        NSApp.activate(ignoringOtherApps: true)

        if let menubarWindow = NSApp.windows.first(where: { $0.isVisible && !$0.title.lowercased().contains("settings") }) {
            menubarWindow.makeKeyAndOrderFront(nil)
            menubarWindow.orderFrontRegardless()
        } else {
            statusItemButton?.performClick(nil)
        }

        statusItemButton?.highlight(true)
    }

    func focusMenubarButton() {
        statusItemButton?.highlight(true)
    }

    func clearFocus() {
        statusItemButton?.highlight(false)
    }
}
