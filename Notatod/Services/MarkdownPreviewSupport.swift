import Foundation
import MarkdownUI
import Splash
import SwiftUI

struct TextOutputFormat: OutputFormat {
    private let theme: Splash.Theme

    init(theme: Splash.Theme) {
        self.theme = theme
    }

    func makeBuilder() -> Builder {
        Builder(theme: theme)
    }

    struct Builder: OutputBuilder {
        private let theme: Splash.Theme
        private var accumulatedText: [Text] = []

        init(theme: Splash.Theme) {
            self.theme = theme
        }

        mutating func addToken(_ token: String, ofType type: TokenType) {
            let color = theme.tokenColors[type] ?? theme.plainTextColor
            accumulatedText.append(Text(token).foregroundStyle(Color(nsColor: color)))
        }

        mutating func addPlainText(_ text: String) {
            accumulatedText.append(Text(text).foregroundStyle(Color(nsColor: theme.plainTextColor)))
        }

        mutating func addWhitespace(_ whitespace: String) {
            accumulatedText.append(Text(whitespace))
        }

        func build() -> Text {
            accumulatedText.reduce(Text(""), +)
        }
    }
}

struct SplashCodeSyntaxHighlighter: CodeSyntaxHighlighter {
    private let syntaxHighlighter: SyntaxHighlighter<TextOutputFormat>

    init(theme: Splash.Theme) {
        self.syntaxHighlighter = SyntaxHighlighter(format: TextOutputFormat(theme: theme))
    }

    func highlightCode(_ content: String, language: String?) -> Text {
        guard language != nil else {
            return Text(content)
        }

        return syntaxHighlighter.highlight(content)
    }
}

extension CodeSyntaxHighlighter where Self == SplashCodeSyntaxHighlighter {
    static func splash(theme: Splash.Theme) -> Self {
        SplashCodeSyntaxHighlighter(theme: theme)
    }
}

enum MarkdownPreviewSupport {
    static func codeSyntaxHighlighter() -> some CodeSyntaxHighlighter {
        SplashCodeSyntaxHighlighter(theme: .sunset(withFont: .init(size: 13)))
    }
}
