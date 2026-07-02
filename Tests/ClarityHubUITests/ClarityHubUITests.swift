import XCTest

final class ClarityHubUITests: XCTestCase {
    private let visibleTabs = ["Today", "Body", "Goals", "Habits"]
    private let moreTabs = ["Lists", "Calendar", "Nutrition", "Review", "Settings"]

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testV1SurfacesRenderInLightAndDarkMode() {
        assertV1SurfacesRender(interfaceStyle: "Light")
        assertV1SurfacesRender(interfaceStyle: "Dark")
    }

    private func assertV1SurfacesRender(interfaceStyle: String) {
        let app = XCUIApplication()
        app.launchEnvironment["CLARITYHUB_IN_MEMORY_STORE"] = "1"
        app.launchArguments += ["-AppleInterfaceStyle", interfaceStyle]
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "Tab bar should render in \(interfaceStyle) mode.")

        for title in visibleTabs {
            openVisibleTab(title, in: app)
            assertScreenTitle(title, in: app, interfaceStyle: interfaceStyle)
        }

        for title in moreTabs {
            openMoreTab(title, in: app)
            assertScreenTitle(title, in: app, interfaceStyle: interfaceStyle)
        }
    }

    private func openVisibleTab(_ title: String, in app: XCUIApplication) {
        let button = app.tabBars.buttons[title]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "\(title) tab should be visible.")
        button.tap()
    }

    private func openMoreTab(_ title: String, in app: XCUIApplication) {
        let moreButton = app.tabBars.buttons["More"]
        XCTAssertTrue(moreButton.waitForExistence(timeout: 5), "More tab should expose \(title).")
        moreButton.tap()

        let cell = app.cells.containing(.staticText, identifier: title).firstMatch
        if !cell.waitForExistence(timeout: 2) {
            let moreBackButton = app.navigationBars.buttons["More"]
            if moreBackButton.exists {
                moreBackButton.tap()
            }
        }

        XCTAssertTrue(cell.waitForExistence(timeout: 5), "\(title) should be listed under More.")
        cell.tap()
    }

    private func assertScreenTitle(_ title: String, in app: XCUIApplication, interfaceStyle: String) {
        let titleElement = app.staticTexts["screenTitle.\(title)"]
        XCTAssertTrue(
            titleElement.waitForExistence(timeout: 5),
            "\(title) screen should render in \(interfaceStyle) mode."
        )
    }
}
