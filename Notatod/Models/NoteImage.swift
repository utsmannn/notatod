import Foundation
import SwiftData

@Model
final class NoteImage {
    var id: UUID
    var filename: String
    var createdAt: Date
    var note: Note?

    init(
        id: UUID = UUID(),
        filename: String,
        createdAt: Date = .now,
        note: Note? = nil
    ) {
        self.id = id
        self.filename = filename
        self.createdAt = createdAt
        self.note = note
    }
}
