import Foundation
import SwiftData

enum PersistenceBootstrap {
    static let schema = Schema([
        Note.self,
        NoteImage.self
    ])

    static func makeModelContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
