import SwiftUI
import SwiftData

struct SplitEditorView: View {
    @Environment(EditorSession.self) private var session
    @Environment(SettingsService.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Environment(SyncService.self) private var syncService

    let note: Note

    private var localStatusText: String {
        session.isDirty ? "Autosaving…" : "Saved"
    }

    private var syncStatusText: String {
        switch syncService.syncState.status {
        case .notConnected:
            return "Not sync"
        case .synced:
            return "Synced"
        case .syncing:
            return "Syncing…"
        case .offline:
            return "Offline"
        case .error(let message):
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Sync error" : trimmed
        }
    }

    private var syncStatusColor: Color {
        switch syncService.syncState.status {
        case .notConnected:
            return .secondary
        case .synced:
            return .green
        case .syncing:
            return .yellow
        case .offline:
            return .secondary
        case .error:
            return .red
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            EditorView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                Text(session.titleFromContent)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                Text(localStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Circle()
                        .fill(syncStatusColor)
                        .frame(width: 8, height: 8)
                    Text(syncStatusText)
                        .font(.caption)
                        .foregroundStyle(syncStatusColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .id("\(note.id)-\(settings.editorFontSize)")
        .onAppear {
            bindAutosave()
        }
        .onChange(of: note.id) { _, _ in
            bindAutosave()
        }
        .onChange(of: session.draft) { _, _ in
            syncTitleFromContent()
        }
    }

    private func bindAutosave() {
        SyncDebugLogger.log("[SplitEditorView.bindAutosave] note=\(note.id) sessionNote=\(session.noteID?.uuidString ?? "nil")")
        session.onAutosave = {
            SyncDebugLogger.log("[SplitEditorView.onAutosave] note=\(note.id) sessionNote=\(session.noteID?.uuidString ?? "nil") dirty=\(session.isDirty)")
            guard session.noteID == note.id, session.isDirty else { return }
            let repository = NoteRepository(modelContext: modelContext, syncService: syncService)
            try? repository.save(note: note, content: session.draft)
            session.markSaved(at: note.modifiedAt)
        }
    }

    private func syncTitleFromContent() {
        let newTitle = session.titleFromContent
        guard note.title != newTitle else { return }

        let repository = NoteRepository(modelContext: modelContext, syncService: syncService)
        try? repository.save(note: note, title: newTitle, content: session.draft)
        session.markSaved(at: note.modifiedAt)
    }
}
