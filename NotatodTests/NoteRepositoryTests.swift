import SwiftData
import Testing
@testable import Notatod

@MainActor
struct NoteRepositoryTests {
    @Test
    func bootstrapCreatesWelcomeNote() throws {
        let container = try PersistenceBootstrap.makeModelContainer(inMemory: true)
        let repository = NoteRepository(modelContext: container.mainContext)

        try repository.bootstrapIfNeeded()

        let notes = try container.mainContext.fetch(FetchDescriptor<Note>())
        #expect(notes.count == 1)
        #expect(notes.first?.title == "Welcome to Notatod")
    }
}
