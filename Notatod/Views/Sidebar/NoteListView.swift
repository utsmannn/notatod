import SwiftUI
import SwiftData

struct NoteListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openSettings) private var openSettings
    @Environment(\.modelContext) private var modelContext
    @Environment(SyncService.self) private var syncService
    let notes: [Note]
    @Binding var selectedNoteID: UUID?

    private var selectedNote: Note? {
        guard let selectedNoteID else { return nil }
        return notes.first(where: { $0.id == selectedNoteID })
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field at top
            TextField("Search…", text: Bindable(appState).searchQuery)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 8)
                .padding(.top)

            // Notes list
            List(notes, selection: $selectedNoteID) { note in
                NoteRowView(note: note)
                    .tag(note.id)
                    .contextMenu {
                        Button(note.isPinned ? "Unpin" : "Pin") {
                            let repository = NoteRepository(modelContext: modelContext, syncService: syncService)
                            try? repository.togglePin(for: note)
                        }

                        Button("Delete", role: .destructive) {
                            let repository = NoteRepository(modelContext: modelContext, syncService: syncService)
                            let deletedID = note.id
                            try? repository.delete(note: note)
                            if selectedNoteID == deletedID {
                                selectedNoteID = notes.first(where: { $0.id != deletedID })?.id
                            }
                        }
                    }
            }
            .listStyle(.sidebar)

            Divider()

            HStack(spacing: 8) {
                Button {
                    let repository = NoteRepository(modelContext: modelContext, syncService: syncService)
                    if let note = try? repository.createNote() {
                        selectedNoteID = note.id
                    }
                } label: {
                    Label("New", systemImage: "doc.badge.plus")
                        .labelStyle(.titleAndIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("New Note")

                Button {
                    appState.selectSettingsTab(.sync)
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Label("Sync", systemImage: "arrow.triangle.2.circlepath.icloud")
                        .labelStyle(.titleAndIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Sync with Google Drive")

                Button {
                    appState.selectSettingsTab(.general)
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Label("Settings", systemImage: "gearshape")
                        .labelStyle(.iconOnly)
                        .frame(width: 30)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Settings")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(.regularMaterial)
            .zIndex(1)
        }
        .frame(maxHeight: .infinity)
    }
}
