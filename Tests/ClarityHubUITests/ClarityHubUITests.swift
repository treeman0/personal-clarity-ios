import XCTest

final class ClarityHubUITests: XCTestCase {
    private let visibleTabs = ["Today", "Body", "Goals", "Habits"]
    private let moreTabs = ["Lists", "Calendar", "Nutrition", "Review", "Settings"]
    private let setupSectionExpectations: [String: String] = [
        "Today": "section.Setup",
        "Body": "section.Trend",
        "Goals": "section.Add goal",
        "Habits": "section.Add habit",
        "Lists": "section.Add list",
        "Calendar": "section.Upcoming",
        "Nutrition": "section.Today",
        "Review": "section.Wins",
        "Settings": "section.Body target"
    ]

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testV1SurfacesRenderInLightAndDarkMode() {
        assertV1SurfacesRender(interfaceStyle: "Light")
        assertV1SurfacesRender(interfaceStyle: "Dark")
    }

    func testDenseTodayDataRendersInLightAndDarkMode() {
        assertDenseTodayDataRenders(interfaceStyle: "Light")
        assertDenseTodayDataRenders(interfaceStyle: "Dark")
    }

    func testDenseFixtureRecordsRenderAcrossPrimaryAreas() {
        let app = launchDenseFixture(interfaceStyle: "Light")
        defer { app.terminate() }

        openVisibleTab("Goals", in: app)
        assertScreenTitle("Goals", in: app, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilStaticText("Reach 180 lb with steady weekly gain", in: app))
        XCTAssertTrue(scrollUntilElement(withIdentifier: "section.Reach 180 lb with steady weekly gain", in: app))

        openVisibleTab("Habits", in: app)
        assertScreenTitle("Habits", in: app, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilStaticText("Prepare high-protein breakfast before first work block", in: app))

        openMoreTab("Lists", in: app)
        assertScreenTitle("Lists", in: app, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilStaticText("Write the focused next action with enough detail to test long text wrapping in the Today priority queue", in: app))
        XCTAssertTrue(scrollUntilStaticText("A working daily hub that survives dense real-life data without losing scanability.", in: app))

        openMoreTab("Calendar", in: app)
        assertScreenTitle("Calendar", in: app, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilStaticText("Google OAuth is configured.", in: app))

        openMoreTab("Nutrition", in: app)
        assertScreenTitle("Nutrition", in: app, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilStaticText("Cal AI import", in: app))
        XCTAssertTrue(scrollUntilElement(withIdentifier: "section.Recent average", in: app))

        openMoreTab("Review", in: app)
        assertScreenTitle("Review", in: app, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilStaticText("Protect the first training-support block and complete the highest priority clarity task.", in: app))

        openMoreTab("Settings", in: app)
        assertScreenTitle("Settings", in: app, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilElement(withIdentifier: "section.Body target", in: app))
        XCTAssertTrue(scrollUntilElement(withIdentifier: "section.Google Calendar", in: app))
    }

    func testHealthKitEmptyStateCopyRendersInBodyAndNutrition() {
        let app = launchHealthKitFixture(state: "empty", interfaceStyle: "Light")
        defer { app.terminate() }

        openVisibleTab("Body", in: app)
        assertScreenTitle("Body", in: app, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilStaticText("No body-weight samples were available. If you denied Health permission, enable Body Measurements access in the Health app settings.", in: app))

        openMoreTab("Nutrition", in: app)
        assertScreenTitle("Nutrition", in: app, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilButton("Connect nutrition totals", in: app))
        app.buttons["Connect nutrition totals"].tap()
        XCTAssertTrue(scrollUntilStaticText("Apple Health has no calorie or macro totals for today, or nutrition permission was not granted.", in: app))
    }

    func testHealthKitDeniedStateCopyRendersInSetupBodyAndNutrition() {
        let app = launchHealthKitFixture(state: "denied", interfaceStyle: "Light")
        defer { app.terminate() }

        XCTAssertTrue(scrollUntilButton("Authorize", in: app))
        app.buttons["Authorize"].tap()
        XCTAssertTrue(scrollUntilStaticText("Some permissions could not be completed.", in: app))

        openVisibleTab("Body", in: app)
        assertScreenTitle("Body", in: app, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilStaticText("Apple Health weight could not be loaded. Check Health permission and try again.", in: app))

        openMoreTab("Nutrition", in: app)
        assertScreenTitle("Nutrition", in: app, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilButton("Connect nutrition totals", in: app))
        app.buttons["Connect nutrition totals"].tap()
        XCTAssertTrue(scrollUntilStaticText("Apple Health nutrition could not be loaded. Check Health permission and try again.", in: app))
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
            assertSetupSection(for: title, in: app, interfaceStyle: interfaceStyle)
        }

        for title in moreTabs {
            openMoreTab(title, in: app)
            assertScreenTitle(title, in: app, interfaceStyle: interfaceStyle)
            assertSetupSection(for: title, in: app, interfaceStyle: interfaceStyle)
        }
    }

    private func assertDenseTodayDataRenders(interfaceStyle: String) {
        let app = launchDenseFixture(interfaceStyle: interfaceStyle)
        defer { app.terminate() }

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "Tab bar should render in \(interfaceStyle) mode.")
        assertScreenTitle("Today", in: app, interfaceStyle: interfaceStyle)

        XCTAssertTrue(scrollUntilElement(withIdentifier: "section.Focus", in: app), "Dense Today should show focus in \(interfaceStyle) mode.")
        XCTAssertTrue(app.staticTexts["Protect the first training-support block and complete the highest priority clarity task."].waitForExistence(timeout: 2))

        XCTAssertTrue(scrollUntilElement(withIdentifier: "section.Next actions", in: app), "Dense Today should show next actions in \(interfaceStyle) mode.")
        XCTAssertTrue(app.staticTexts["Write the focused next action with enough detail to test long text wrapping in the Today priority queue"].waitForExistence(timeout: 2))

        XCTAssertTrue(scrollUntilElement(withIdentifier: "section.Nutrition signal", in: app), "Dense Today should show nutrition signal in \(interfaceStyle) mode.")
        XCTAssertTrue(scrollUntilElement(withIdentifier: "section.Goal signal", in: app), "Dense Today should show goal signal in \(interfaceStyle) mode.")
        XCTAssertTrue(app.staticTexts["Reach 180 lb with steady weekly gain"].waitForExistence(timeout: 2))
    }

    private func launchDenseFixture(interfaceStyle: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["CLARITYHUB_IN_MEMORY_STORE"] = "1"
        app.launchEnvironment["CLARITYHUB_UI_TEST_FIXTURE"] = "dense"
        app.launchArguments += ["-AppleInterfaceStyle", interfaceStyle]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "Tab bar should render in \(interfaceStyle) mode.")
        return app
    }

    private func launchHealthKitFixture(state: String, interfaceStyle: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["CLARITYHUB_IN_MEMORY_STORE"] = "1"
        app.launchEnvironment["CLARITYHUB_HEALTHKIT_FIXTURE"] = state
        app.launchArguments += ["-AppleInterfaceStyle", interfaceStyle]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "Tab bar should render in \(interfaceStyle) mode.")
        return app
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

    private func assertSetupSection(for title: String, in app: XCUIApplication, interfaceStyle: String) {
        guard let expectedIdentifier = setupSectionExpectations[title] else { return }
        XCTAssertTrue(
            scrollUntilElement(withIdentifier: expectedIdentifier, in: app),
            "\(title) should show expected setup section in \(interfaceStyle) mode."
        )
    }

    private func scrollUntilElement(withIdentifier identifier: String, in app: XCUIApplication) -> Bool {
        let element = app.descendants(matching: .any)[identifier]
        if element.waitForExistence(timeout: 2) {
            return true
        }

        let scrollView = app.scrollViews.firstMatch
        guard scrollView.exists else {
            return false
        }

        for _ in 0..<4 {
            scrollView.swipeUp()
            if element.waitForExistence(timeout: 1) {
                return true
            }
        }

        return false
    }

    private func scrollUntilStaticText(_ text: String, in app: XCUIApplication) -> Bool {
        let element = app.staticTexts.matching(NSPredicate(format: "label == %@", text)).firstMatch
        if element.waitForExistence(timeout: 2) {
            return true
        }

        let scrollView = app.scrollViews.firstMatch
        guard scrollView.exists else {
            return false
        }

        for _ in 0..<5 {
            scrollView.swipeUp()
            if element.waitForExistence(timeout: 1) {
                return true
            }
        }

        return false
    }

    private func scrollUntilButton(_ label: String, in app: XCUIApplication) -> Bool {
        let button = app.buttons[label]
        if button.waitForExistence(timeout: 2) {
            return true
        }

        let scrollView = app.scrollViews.firstMatch
        guard scrollView.exists else {
            return false
        }

        for _ in 0..<5 {
            scrollView.swipeUp()
            if button.waitForExistence(timeout: 1) {
                return true
            }
        }

        return false
    }
}
