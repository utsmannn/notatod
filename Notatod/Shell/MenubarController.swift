import AppKit
import Observation

@MainActor
@Observable
final class MenubarController {
    struct PanelGeometry {
        let minWidth: CGFloat
        let idealWidth: CGFloat
        let maxWidth: CGFloat
        let minHeight: CGFloat
        let idealHeight: CGFloat
        let maxHeight: CGFloat
    }

    private(set) weak var statusItemButton: NSStatusBarButton?

    var panelGeometry: PanelGeometry {
        Self.panelGeometry(for: activeScreen())
    }

    func bindStatusItemButton(_ button: NSStatusBarButton?) {
        statusItemButton = button
    }

    func revealEditorPanel() {
        NSApp.activate(ignoringOtherApps: true)

        if let menubarWindow = visibleMenubarWindow() {
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

    private func activeScreen() -> NSScreen? {
        if let buttonScreen = statusItemButton?.window?.screen {
            return buttonScreen
        }

        if let menubarWindowScreen = visibleMenubarWindow()?.screen {
            return menubarWindowScreen
        }

        return NSScreen.main
    }

    private func visibleMenubarWindow() -> NSWindow? {
        NSApp.windows.first(where: { window in
            window.isVisible && !window.title.lowercased().contains("settings")
        })
    }

    private static func panelGeometry(for screen: NSScreen?) -> PanelGeometry {
        let visibleFrame = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1512, height: 982)

        let idealWidth = clamp(visibleFrame.width * 0.6, min: 820, max: 1180)
        let minWidth = clamp(idealWidth * 0.82, min: 680, max: idealWidth)
        let maxWidth = clamp(visibleFrame.width * 0.72, min: idealWidth, max: 1280)

        let idealHeight = clamp(visibleFrame.height * 0.66, min: 560, max: 860)
        let minHeight = clamp(idealHeight * 0.82, min: 460, max: idealHeight)
        let maxHeight = clamp(visibleFrame.height * 0.8, min: idealHeight, max: 940)

        return PanelGeometry(
            minWidth: minWidth,
            idealWidth: idealWidth,
            maxWidth: maxWidth,
            minHeight: minHeight,
            idealHeight: idealHeight,
            maxHeight: maxHeight
        )
    }

    private static func clamp(_ value: CGFloat, min lowerBound: CGFloat, max upperBound: CGFloat) -> CGFloat {
        Swift.max(lowerBound, Swift.min(value, upperBound))
    }
}
