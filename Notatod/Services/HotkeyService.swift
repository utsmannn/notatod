import AppKit
import HotKey

@MainActor
final class HotkeyService {
    private var hotKey: HotKey?
    var onToggle: (() -> Void)?

    init() {
        updateHotKey()
    }

    func updateHotKey(key: Key = .n, modifiers: NSEvent.ModifierFlags = [.command, .shift]) {
        hotKey = HotKey(key: key, modifiers: modifiers)
        hotKey?.keyDownHandler = { [weak self] in
            self?.onToggle?()
        }
    }
}
