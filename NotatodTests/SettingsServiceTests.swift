import Foundation
import Testing
@testable import Notatod

@MainActor
struct SettingsServiceTests {
    @Test
    func fontSizePersistsToDefaults() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let service = SettingsService(defaults: defaults)

        service.editorFontSize = 18

        #expect(service.editorFontSize == 18)
    }
}
