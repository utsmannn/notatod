import Combine
import Foundation
import Observation

@MainActor
@Observable
final class EditorSession {
    private(set) var noteID: UUID?
    var draft = ""
    private(set) var lastSavedDraft = ""
    private(set) var lastSavedAt: Date?

    private let autosaveSubject = PassthroughSubject<String, Never>()
    private var autosaveCancellable: AnyCancellable?

    var isDirty: Bool {
        draft != lastSavedDraft
    }

    var titleFromContent: String {
        let firstLine = draft.split(separator: "\n", omittingEmptySubsequences: false).first ?? ""
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
        // Remove leading # if present (markdown H1)
        if trimmed.hasPrefix("#") {
            return trimmed.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces)
        }
        return trimmed
    }

    var onAutosave: (() -> Void)?

    init() {
        autosaveCancellable = autosaveSubject
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.onAutosave?()
            }
    }

    func load(note: Note) {
        noteID = note.id
        draft = note.content
        lastSavedDraft = note.content
        lastSavedAt = note.modifiedAt
    }

    func updateDraft(_ value: String) {
        draft = value
        SyncDebugLogger.log("[EditorSession.updateDraft] note=\(noteID?.uuidString ?? "nil") dirty=\(isDirty) length=\(value.count)")
        autosaveSubject.send(value)
    }

    func markSaved(at date: Date = .now) {
        lastSavedDraft = draft
        lastSavedAt = date
    }

    func reset() {
        noteID = nil
        draft = ""
        lastSavedDraft = ""
        lastSavedAt = nil
    }

    func flushPendingAutosave() {
        autosaveCancellable?.cancel()
        onAutosave?()
        // Re-create cancellable for future autosaves
        autosaveCancellable = autosaveSubject
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.onAutosave?()
            }
    }
}
