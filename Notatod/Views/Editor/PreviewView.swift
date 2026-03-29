import SwiftUI
import MarkdownUI

struct PreviewView: View {
    let content: String

    var body: some View {
        ScrollView {
            Markdown(content)
                .markdownTheme(.gitHub)
                .markdownCodeSyntaxHighlighter(MarkdownPreviewSupport.codeSyntaxHighlighter())
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
}
