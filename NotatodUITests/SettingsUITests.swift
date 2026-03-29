import XCTest

final class SettingsUITests: XCTestCase {
    func testLaunchForSettingsFlow() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertNotNil(app)
    }
}
