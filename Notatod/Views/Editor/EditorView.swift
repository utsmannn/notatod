import SwiftUI

struct EditorView: View {
    @Environment(EditorSession.self) private var session
    @Environment(SettingsService.self) private var settings

    var body: some View {
        MarkdownTextEditor(
            text: Binding(
                get: { session.draft },
                set: { _ in }
            ),
            fontSize: settings.editorFontSize,
            onTextChange: { newText in
                session.updateDraft(newText)
            }
        )
        .padding(8)
    }
}
