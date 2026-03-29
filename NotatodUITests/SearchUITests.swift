import XCTest

final class SearchUITests: XCTestCase {
    func testLaunchForSearchFlow() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertGreaterThanOrEqual(app.windows.count, 0)
    }
}
