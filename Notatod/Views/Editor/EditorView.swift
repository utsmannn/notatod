import SwiftUI

struct EditorView: View {
    @Environment(EditorSession.self) private var session
    @Environment(SettingsService.self) private var settings

    var body: some View {
        MarkdownTextEditor(
            text: Binding(
                get: { session.draft },
                set: { _ in } // Handled by onTextChange
            ),
            fontSize: settings.editorFontSize,
            onTextChange: { newText in
                let processed = ensureFirstLineHasHeading(newText)
                if processed != newText {
                    // If we modified the text, update with processing
                    session.updateDraft(processed)
                } else {
                    session.updateDraft(newText)
                }
            }
        )
        .padding(8)
    }

    private func ensureFirstLineHasHeading(_ text: String) -> String {
        // If text is empty, return as is
        guard !text.isEmpty else { return text }

        // Split into lines
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        // If no lines, return as is
        guard !lines.isEmpty else { return text }

        let firstLine = lines[0].trimmingCharacters(in: .whitespaces)

        // If first line is empty and we're starting to type, prepend #
        if firstLine.isEmpty {
            lines[0] = "# " + lines[0]
            return lines.joined(separator: "\n")
        }

        // If first line doesn't start with #, prepend it
        if !firstLine.hasPrefix("#") {
            lines[0] = "# " + lines[0]
            return lines.joined(separator: "\n")
        }

        return text
    }
}
