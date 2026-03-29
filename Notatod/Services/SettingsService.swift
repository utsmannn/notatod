import Foundation
import Observation
import ServiceManagement

@MainActor
@Observable
final class SettingsService {
    var editorFontSize: Double {
        didSet {
            defaults.set(editorFontSize, forKey: Keys.editorFontSize)
        }
    }

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set {
            defaults.set(newValue, forKey: Keys.launchAtLogin)
            syncLaunchAtLogin()
        }
    }

    var appearance: AppState.Appearance {
        get {
            AppState.Appearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "system") ?? .system
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.appearance)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedValue = defaults.double(forKey: Keys.editorFontSize)
        self.editorFontSize = storedValue == 0 ? 14 : storedValue
    }

    func syncLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
        }
    }

    private enum Keys {
        static let editorFontSize = "editorFontSize"
        static let launchAtLogin = "launchAtLogin"
        static let appearance = "appearance"
    }
}
