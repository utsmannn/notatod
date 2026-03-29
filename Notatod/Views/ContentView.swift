import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(EditorSession.self) private var editorSession
    @Environment(\.openSettings) private var openSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(SyncService.self) private var syncService
    @Query private var notes: [Note]

    init() {}

    var filteredNotes: [Note] {
        let sortedNotes = notes.sorted {
            if $0.isPinned != $1.isPinned {
                return $0.isPinned && !$1.isPinned
            }

            return $0.modifiedAt > $1.modifiedAt
        }

        let query = appState.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sortedNotes }

        return sortedNotes.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.content.localizedCaseInsensitiveContains(query)
        }
    }

    var selectedNote: Note? {
        guard let id = appState.selectedNoteID else { return filteredNotes.first }
        return filteredNotes.first(where: { $0.id == id })
    }

    var body: some View {
        NavigationSplitView {
            NoteListView(notes: filteredNotes, selectedNoteID: Binding(
                get: { appState.selectedNoteID },
                set: { appState.selectNote(id: $0) }
            ))
            .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 220)
        } detail: {
            if let selectedNote {
                SplitEditorView(note: selectedNote)
            } else {
                ContentUnavailableView("No Notes", systemImage: "note.text", description: Text("Create your first note to get started."))
            }
        }
        .onAppear {
            synchronizeSelection(with: filteredNotes)
            loadSelectedNote(appState.selectedNoteID)
        }
        .onChange(of: appState.selectedNoteID) { previousID, newID in
            flushPendingAutosave()
            persistDraft(for: previousID)
            loadSelectedNote(newID)
        }
        .onChange(of: filteredNotes.map(\.id)) { _, _ in
            synchronizeSelection(with: filteredNotes)
        }
        .toolbar { }
    }

    private func flushPendingAutosave() {
        editorSession.flushPendingAutosave()
    }

    private func synchronizeSelection(with notes: [Note]) {
        if let selectedID = appState.selectedNoteID,
           notes.contains(where: { $0.id == selectedID }) {
            return
        }

        appState.selectNote(id: notes.first?.id)
    }

    private func persistDraft(for noteID: UUID?) {
        guard let noteID,
              editorSession.noteID == noteID,
              editorSession.isDirty,
              let note = notes.first(where: { $0.id == noteID }) else {
            return
        }

        let repository = NoteRepository(modelContext: modelContext, syncService: syncService)
        try? repository.save(note: note, content: editorSession.draft)
        editorSession.markSaved(at: note.modifiedAt)
    }

    private func loadSelectedNote(_ noteID: UUID?) {
        guard let noteID,
              let note = notes.first(where: { $0.id == noteID }) else {
            editorSession.reset()
            return
        }

        if editorSession.noteID != note.id {
            editorSession.load(note: note)
        }
    }

}
