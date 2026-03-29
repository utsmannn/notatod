import Foundation
import Testing
@testable import Notatod

@MainActor
struct EditorSessionTests {
    @Test
    func loadMarksSessionClean() {
        let note = Note(title: "Sample", content: "Hello")
        let session = EditorSession()

        session.load(note: note)

        #expect(session.draft == "Hello")
        #expect(session.isDirty == false)
    }
}
