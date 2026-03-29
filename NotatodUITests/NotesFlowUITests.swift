import XCTest

final class NotesFlowUITests: XCTestCase {
    func testLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5) || app.wait(for: .runningBackground, timeout: 5))
    }
}
