import Foundation
import Testing
@testable import Notatod

struct ImageStoreTests {
    @Test
    func markdownReferenceUsesImagesDirectory() {
        let markdown = ImageMarkdownInsertion.markdownReference(for: "sample.jpg")
        #expect(markdown == "![image](images/sample.jpg)")
    }
}
