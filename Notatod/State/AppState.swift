import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    enum SettingsTab: Hashable {
        case general
        case sync
        case about
    }

    enum Appearance: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }
    }

    var searchQuery = ""
    var selectedNoteID: UUID?
    var appearance: Appearance = .system
    var selectedSettingsTab: SettingsTab = .general
    var isSettingsPresented = false
    var isMenubarPresented = false

    func selectNote(id: UUID?) {
        selectedNoteID = id
    }

    func selectSettingsTab(_ tab: SettingsTab) {
        selectedSettingsTab = tab
    }
}
