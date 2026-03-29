import Foundation
import SwiftData

@Model
final class Note {
    var id: UUID
    var title: String
    var content: String
    var isPinned: Bool
    var createdAt: Date
    var modifiedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \NoteImage.note)
    var images: [NoteImage]

    init(
        id: UUID = UUID(),
        title: String = "Untitled",
        content: String = "",
        isPinned: Bool = false,
        createdAt: Date = .now,
        modifiedAt: Date = .now,
        images: [NoteImage] = []
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.images = images
    }
}
