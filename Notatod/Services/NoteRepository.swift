import Foundation
import SwiftData

@MainActor
final class NoteRepository {
    private let modelContext: ModelContext
    private let syncService: SyncService?

    init(modelContext: ModelContext, syncService: SyncService? = nil) {
        self.modelContext = modelContext
        self.syncService = syncService
    }

    func bootstrapIfNeeded() throws {
        var descriptor = FetchDescriptor<Note>()
        descriptor.fetchLimit = 1

        let existing = try modelContext.fetch(descriptor)
        guard existing.isEmpty else { return }

        let welcome = Note(
            title: "Welcome to Notatod",
            content: """
# Welcome to Notatod

Your notes, always accessible.

## Features
- Markdown support
- Image embedding
- Menubar-first workflow
"""
        )

        modelContext.insert(welcome)
        try modelContext.save()
    }

    func createNote(title: String = "Untitled") throws -> Note {
        let note = Note(title: title)
        modelContext.insert(note)
        try modelContext.save()
        SyncDebugLogger.log("[NoteRepository.createNote] note=\(note.id)")
        syncService?.noteDidChange(note)
        return note
    }

    func save(note: Note, title: String? = nil, content: String? = nil) throws {
        if let title {
            note.title = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : title.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let content {
            note.content = content
        }

        note.modifiedAt = .now
        try modelContext.save()
        SyncDebugLogger.log("[NoteRepository.save] note=\(note.id) modifiedAt=\(note.modifiedAt)")
        syncService?.noteDidChange(note)
    }

    func delete(note: Note) throws {
        let noteID = note.id
        modelContext.delete(note)
        try modelContext.save()
        guard let syncService else { return }
        Task {
            do {
                try await syncService.noteDidDelete(id: noteID)
            } catch {
                await MainActor.run {
                    syncService.syncState.markError(error.localizedDescription)
                }
            }
        }
    }

    func rename(note: Note, title: String) throws {
        note.title = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : title.trimmingCharacters(in: .whitespacesAndNewlines)
        note.modifiedAt = .now
        try modelContext.save()
        syncService?.noteDidChange(note)
    }

    func togglePin(for note: Note) throws {
        note.isPinned.toggle()
        note.modifiedAt = .now
        try modelContext.save()
        syncService?.noteDidChange(note)
    }
}
