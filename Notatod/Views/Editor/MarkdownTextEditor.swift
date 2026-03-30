import SwiftUI

// MARK: - Markdown Header Text Editor

struct MarkdownTextEditor: NSViewRepresentable {
    @Binding var text: String
    var fontSize: Double
    var onTextChange: (String) -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.drawsBackground = false
        scrollView.contentView.drawsBackground = false

        let textView = MarkdownHeaderTextView()
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.baseFontSize = fontSize
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isSelectable = true
        textView.isEditable = true
        textView.delegate = context.coordinator

        textView.backgroundColor = .clear
        textView.drawsBackground = false

        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]

        let container = textView.textContainer!
        container.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        container.widthTracksTextView = true

        scrollView.documentView = textView

        textView.string = text
        textView.applyHeaderStyles()
        context.coordinator.lastSyncedText = text

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? MarkdownHeaderTextView else { return }

        context.coordinator.parent = self

        scrollView.drawsBackground = false
        scrollView.contentView.drawsBackground = false
        textView.drawsBackground = false
        textView.backgroundColor = .clear

        if textView.baseFontSize != fontSize {
            textView.baseFontSize = fontSize
            textView.applyHeaderStyles()
        }

        guard textView.string != text else {
            context.coordinator.lastSyncedText = text
            return
        }

        guard context.coordinator.lastSyncedText != text else {
            return
        }

        let selectedRange = textView.selectedRange()
        context.coordinator.isApplyingExternalText = true
        textView.string = text
        context.coordinator.isApplyingExternalText = false
        context.coordinator.lastSyncedText = text
        textView.applyHeaderStyles()
        textView.setSelectedRange(clampedRange(selectedRange, for: text))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func clampedRange(_ range: NSRange, for text: String) -> NSRange {
        let length = (text as NSString).length
        let location = min(range.location, length)
        let maxLength = max(0, length - location)
        return NSRange(location: location, length: min(range.length, maxLength))
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownTextEditor
        var isApplyingExternalText = false
        var lastSyncedText = ""

        init(_ parent: MarkdownTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isApplyingExternalText,
                  let textView = notification.object as? MarkdownHeaderTextView else { return }
            let updatedText = textView.string
            lastSyncedText = updatedText
            textView.applyHeaderStyles()
            parent.onTextChange(updatedText)
        }
    }
}

// MARK: - Custom Text View with Header Styling

class MarkdownHeaderTextView: NSTextView {
    var baseFontSize: Double = 14

    override func keyDown(with event: NSEvent) {
        // Check for Cmd+B (bold) or Cmd+I (italic)
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers?.lowercased() {
            case "b":
                toggleBold()
                return
            case "i":
                toggleItalic()
                return
            default:
                break
            }
        }
        super.keyDown(with: event)
    }

    private func toggleBold() {
        let selectedRange = self.selectedRange()
        guard selectedRange.length > 0 else { return }

        let text = self.string
        guard let range = Range(selectedRange, in: text) else { return }

        let selectedText = String(text[range])

        // Check if already bold (wrapped in **)
        if selectedText.hasPrefix("**") && selectedText.hasSuffix("**") {
            // Remove bold markers
            let newText = String(selectedText.dropFirst(2).dropLast(2))
            replaceSelectedText(with: newText)
        } else {
            // Add bold markers
            replaceSelectedText(with: "**\(selectedText)**")
        }
    }

    private func toggleItalic() {
        let selectedRange = self.selectedRange()
        guard selectedRange.length > 0 else { return }

        let text = self.string
        guard let range = Range(selectedRange, in: text) else { return }

        let selectedText = String(text[range])

        // Check if already italic (wrapped in *)
        if selectedText.hasPrefix("*") && selectedText.hasSuffix("*") && !selectedText.hasPrefix("**") {
            // Remove italic markers
            let newText = String(selectedText.dropFirst(1).dropLast(1))
            replaceSelectedText(with: newText)
        } else {
            // Add italic markers
            replaceSelectedText(with: "*\(selectedText)*")
        }
    }

    private func replaceSelectedText(with newText: String) {
        let range = selectedRange()
        guard shouldChangeText(in: range, replacementString: newText) else { return }

        textStorage?.replaceCharacters(in: range, with: newText)
        didChangeText()

        let newRange = NSRange(location: range.location, length: newText.utf16.count)
        setSelectedRange(newRange)
        applyHeaderStyles()
    }

    func applyHeaderStyles() {
        let text = self.string
        let fullRange = NSRange(location: 0, length: text.utf16.count)

        // Reset to base font first
        let baseFont = NSFont.monospacedSystemFont(ofSize: baseFontSize, weight: .regular)
        self.textStorage?.addAttribute(.font, value: baseFont, range: fullRange)

        // Apply header styles
        applyHeaderStyles(to: text)

        // Apply bold styles
        applyBoldStyles(to: text)

        // Apply italic styles
        applyItalicStyles(to: text)
    }

    private func applyHeaderStyles(to text: String) {
        let lines = text.components(separatedBy: .newlines)
        var location = 0

        for line in lines {
            let lineRange = NSRange(location: location, length: line.utf16.count)

            // Check for header pattern (#, ##, ###, etc.)
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if let headerLevel = detectHeaderLevel(trimmedLine) {
                let fontSize = fontSizeForHeaderLevel(headerLevel)
                let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)
                self.textStorage?.addAttribute(.font, value: font, range: lineRange)
            }

            // Move to next line (add 1 for newline character)
            location += line.utf16.count + 1
        }
    }

    private func applyBoldStyles(to text: String) {
        // Pattern for bold: **text** or __text__
        let patterns = [
            "\\*\\*(.+?)\\*\\*",  // **text**
            "__(.+?)__"            // __text__
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

            for match in matches {
                // Apply bold to the content inside markers
                let contentRange = match.range(at: 1)
                let existingFont = self.textStorage?.attribute(.font, at: contentRange.location, effectiveRange: nil) as? NSFont
                let existingSize = existingFont?.pointSize ?? CGFloat(baseFontSize)
                let boldFont = NSFont.monospacedSystemFont(ofSize: existingSize, weight: .bold)
                self.textStorage?.addAttribute(.font, value: boldFont, range: contentRange)
            }
        }
    }

    private func applyItalicStyles(to text: String) {
        // Pattern for italic: *text* or _text_ (but not ** or __)
        let patterns = [
            "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)",  // *text* (not between **)
            "(?<!_)_(?!_)(.+?)(?<!_)_(?!_)"                // _text_ (not between __)
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

            for match in matches {
                // Apply italic to the content inside markers
                let contentRange = match.range(at: 1)
                let existingFont = self.textStorage?.attribute(.font, at: contentRange.location, effectiveRange: nil) as? NSFont
                let existingSize = existingFont?.pointSize ?? CGFloat(baseFontSize)
                let existingWeight = existingFont?.fontDescriptor.symbolicTraits.contains(.bold) == true ? NSFont.Weight.bold : NSFont.Weight.regular

                // Keep bold if already bold, add italic
                let traits: NSFontDescriptor.SymbolicTraits = existingWeight == .bold ? [.bold, .italic] : .italic
                let descriptor = NSFont.monospacedSystemFont(ofSize: existingSize, weight: existingWeight).fontDescriptor.withSymbolicTraits(traits)
                let italicFont = NSFont(descriptor: descriptor, size: existingSize) ?? NSFont.monospacedSystemFont(ofSize: existingSize, weight: existingWeight)
                self.textStorage?.addAttribute(.font, value: italicFont, range: contentRange)
            }
        }
    }

    private func detectHeaderLevel(_ line: String) -> Int? {
        let pattern = "^(#{1,6})\\s"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)) else {
            return nil
        }

        let hashRange = match.range(at: 1)
        if let range = Range(hashRange, in: line) {
            return String(line[range]).count
        }
        return nil
    }

    private func fontSizeForHeaderLevel(_ level: Int) -> CGFloat {
        switch level {
        case 1: return CGFloat(baseFontSize * 1.8)  // H1: largest
        case 2: return CGFloat(baseFontSize * 1.5)  // H2
        case 3: return CGFloat(baseFontSize * 1.3)  // H3
        case 4: return CGFloat(baseFontSize * 1.15) // H4
        case 5: return CGFloat(baseFontSize * 1.05) // H5
        case 6: return CGFloat(baseFontSize * 1.0)  // H6: same as base
        default: return CGFloat(baseFontSize)
        }
    }
}
