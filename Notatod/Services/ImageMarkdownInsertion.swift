import Foundation

enum ImageMarkdownInsertion {
    static func markdownReference(for filename: String, altText: String = "image") -> String {
        "![\(altText)](images/\(filename))"
    }
}
