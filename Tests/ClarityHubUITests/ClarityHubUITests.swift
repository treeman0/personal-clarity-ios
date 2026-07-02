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

    func testGoogleDisconnectedStateRendersWithoutCalendarAPIAccess() {
        let app = launchGoogleDisconnectedFixture(interfaceStyle: "Light")
        defer { app.terminate() }

        assertScreenTitle("Today", in: app, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilElement(withIdentifier: "section.Calendar blocks", in: app))
        XCTAssertTrue(scrollUntilStaticText("Add a Google OAuth client ID in Settings.", in: app))

        openMoreTab("Settings", in: app)
        assertScreenTitle("Settings", in: app, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilButton("Save Google settings", in: app))
        app.buttons["Save Google settings"].tap()
        XCTAssertTrue(scrollUntilStaticText("Google settings saved.", in: app))

        openMoreTab("Calendar", in: app)
        assertScreenTitle("Calendar", in: app, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilStaticText("Add a Google OAuth client ID in Settings.", in: app))
        XCTAssertTrue(scrollUntilButton("Refresh", in: app))
        app.buttons["Refresh"].tap()
        XCTAssertTrue(scrollUntilStaticText("Add a Google OAuth client ID in Settings.", in: app))
        XCTAssertFalse(app.buttons["Connect"].isEnabled)
    }

    func testReminderScheduleSnoozeSkipControlsRenderSuccessStates() {
        let app = launchReminderFixture(state: "authorized", interfaceStyle: "Light")
        defer { app.terminate() }

        openVisibleTab("Body", in: app)
        assertScreenTitle("Body", in: app, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilButton(containing: "weigh-in reminder", in: app))
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "weigh-in reminder")).firstMatch.tap()
        XCTAssertTrue(scrollUntilStaticText(containing: "Daily reminder scheduled for", in: app))

        XCTAssertTrue(scrollUntilButton("Snooze", in: app))
        app.buttons["Snooze"].tap()
        XCTAssertTrue(scrollUntilStaticText("Snoozed for 15 minutes.", in: app))

        XCTAssertTrue(scrollUntilButton("Skip snooze", in: app))
        app.buttons["Skip snooze"].tap()
        XCTAssertTrue(scrollUntilStaticText("Pending snooze skipped.", in: app))

        openMoreTab("Settings", in: app)
        assertScreenTitle("Settings", in: app, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilButton("Save and schedule reminder", in: app))
        app.buttons["Save and schedule reminder"].tap()
        XCTAssertTrue(scrollUntilStaticText("Saved and scheduled.", in: app))

        openVisibleTab("Today", in: app)
        assertScreenTitle("Today", in: app, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilStaticText(containing: "Scheduled for", in: app))
    }

    func testGoogleConnectedFixtureRendersEventsAndCreatesBlock() {
        let app = launchGoogleConnectedFixture(interfaceStyle: "Light")
        defer { app.terminate() }

        assertScreenTitle("Today", in: app, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilElement(withIdentifier: "section.Calendar blocks", in: app))
        XCTAssertTrue(scrollUntilStaticText("Fixture planning block", in: app))

        openMoreTab("Calendar", in: app)
        assertScreenTitle("Calendar", in: app, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilStaticText("Google OAuth is configured.", in: app))
        XCTAssertTrue(scrollUntilStaticText("Fixture planning block", in: app))

        XCTAssertTrue(scrollUntilButton("Add to Google Calendar", in: app))
        app.buttons["Add to Google Calendar"].tap()
        XCTAssertTrue(scrollUntilStaticText("Added Focus block to Google Calendar.", in: app))
    }

    func testPersistentStoreSurvivesAppRelaunch() {
        let storeName = "ClarityHubUIPersistence-\(UUID().uuidString)"
        let firstLaunch = launchPersistentStoreFixture(
            storeName: storeName,
            seedDenseFixture: true,
            interfaceStyle: "Light"
        )

        assertScreenTitle("Today", in: firstLaunch, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilStaticText("Reach 180 lb with steady weekly gain", in: firstLaunch))
        XCTAssertTrue(scrollUntilStaticText("Protect the first training-support block and complete the highest priority clarity task.", in: firstLaunch))
        firstLaunch.terminate()

        let relaunch = launchPersistentStoreFixture(
            storeName: storeName,
            seedDenseFixture: false,
            interfaceStyle: "Light"
        )
        defer { relaunch.terminate() }

        assertScreenTitle("Today", in: relaunch, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilStaticText("Reach 180 lb with steady weekly gain", in: relaunch))
        XCTAssertTrue(scrollUntilStaticText("Protect the first training-support block and complete the highest priority clarity task.", in: relaunch))

        openVisibleTab("Goals", in: relaunch)
        assertScreenTitle("Goals", in: relaunch, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilStaticText("Reach 180 lb with steady weekly gain", in: relaunch))

        openMoreTab("Nutrition", in: relaunch)
        assertScreenTitle("Nutrition", in: relaunch, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilStaticText("Cal AI import", in: relaunch))

        openMoreTab("Review", in: relaunch)
        assertScreenTitle("Review", in: relaunch, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilStaticText("Protect the first training-support block and complete the highest priority clarity task.", in: relaunch))
    }

    func testNutritionImportFlowUpdatesTodaySignal() {
        let app = launchNutritionImportFixture(interfaceStyle: "Light")
        defer { app.terminate() }

        openMoreTab("Nutrition", in: app)
        assertScreenTitle("Nutrition", in: app, interfaceStyle: "Light")

        XCTAssertTrue(scrollUntilButton("Parse import", in: app))
        app.buttons["Parse import"].tap()
        XCTAssertTrue(scrollUntilStaticText("Import parsed. Review before saving.", in: app))
        XCTAssertTrue(scrollUntilStaticText("3,120 calories, 188.0g protein, 355.0g carbs, 91.0g fat", in: app))

        XCTAssertTrue(scrollUntilButton(containing: "Save", in: app))
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Save")).firstMatch.tap()
        XCTAssertTrue(scrollUntilStaticText(containing: "Saved", in: app))
        XCTAssertTrue(scrollUntilStaticText("Cal AI import", in: app))
        XCTAssertTrue(scrollUntilStaticText("1-day average", in: app))
        XCTAssertTrue(scrollUntilStaticText("3,120 cal - P 188.0g C 355.0g F 91.0g", in: app))

        openVisibleTab("Today", in: app)
        assertScreenTitle("Today", in: app, interfaceStyle: "Light")
        XCTAssertTrue(scrollUntilStaticText("3,120 cal average", in: app))
        XCTAssertTrue(scrollUntilStaticText("P 188.0g C 355.0g F 91.0g over 1 days", in: app))
    }

    func testCoreDataEntryFlowCreatesRecordsAcrossPrimaryAreas() {
        let app = launchBlankFixture(interfaceStyle: "Light")
        defer { app.terminate() }

        openVisibleTab("Goals", in: app)
        assertScreenTitle("Goals", in: app, interfaceStyle: "Light")
        typeText("UI smoke gain goal", intoTextField: "Goal name", in: app)
        XCTAssertTrue(scrollUntilButton("Add goal", in: app))
        app.buttons["Add goal"].tap()
        XCTAssertTrue(scrollUntilStaticText("UI smoke gain goal", in: app))
        captureScreenshot(named: "Light-goal-entry")

        openVisibleTab("Habits", in: app)
        assertScreenTitle("Habits", in: app, interfaceStyle: "Light")
        typeText("UI smoke morning weigh-in", intoTextField: "Habit name", in: app)
        XCTAssertTrue(scrollUntilButton("Add habit", in: app))
        app.buttons["Add habit"].tap()
        XCTAssertTrue(scrollUntilStaticText("UI smoke morning weigh-in", in: app))
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "UI smoke morning weigh-in")).firstMatch.tap()
        XCTAssertTrue(scrollUntilStaticText(containing: "1 streak", in: app))
        captureScreenshot(named: "Light-habit-entry")

        openMoreTab("Lists", in: app)
        assertScreenTitle("Lists", in: app, interfaceStyle: "Light")
        typeText("UI smoke list", intoTextField: "List name", in: app)
        XCTAssertTrue(scrollUntilButton("Add list", in: app))
        app.buttons["Add list"].tap()
        XCTAssertTrue(scrollUntilStaticText("UI smoke list", in: app))

        typeText("UI smoke project", intoTextField: "Project", in: app)
        typeText("Keep the first release candidate focused and easy to inspect.", intoTextField: "Desired outcome", in: app)
        XCTAssertTrue(scrollUntilButton("Add project", in: app))
        app.buttons["Add project"].tap()
        XCTAssertTrue(scrollUntilStaticText("UI smoke project", in: app))

        typeText("UI smoke task", intoTextField: "Task", in: app)
        XCTAssertTrue(scrollUntilButton("Add task", in: app))
        app.buttons["Add task"].tap()
        XCTAssertTrue(scrollUntilStaticText("UI smoke task", in: app))
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "UI smoke task")).firstMatch.tap()
        XCTAssertTrue(scrollUntilButton("Restore UI smoke task", in: app))
        app.buttons["Restore UI smoke task"].tap()
        XCTAssertTrue(scrollUntilStaticText("UI smoke task", in: app))
        captureScreenshot(named: "Light-list-entry")

        openMoreTab("Review", in: app)
        assertScreenTitle("Review", in: app, interfaceStyle: "Light")
        typeText("Shipped a real UI data-entry smoke.", intoTextField: "What moved forward?", in: app)
        typeText("Keep device-only checks explicit.", intoTextField: "What created drag?", in: app)
        typeText("Review the V1 acceptance artifact", intoTextField: "What deserves the first block?", in: app)
        XCTAssertTrue(scrollUntilButton("Save today's review", in: app))
        app.buttons["Save today's review"].tap()

        typeText("Keep acceptance evidence close to CI.", intoTextField: "What should stay in the system?", in: app)
        typeText("Run the device pass as soon as hardware is available.", intoTextField: "What should change next week?", in: app)
        typeText("Finish V1 acceptance", intoTextField: "Primary weekly focus", in: app)
        typeText("Run HealthKit, notifications, Google OAuth, and CloudKit sync.", intoTextField: "Concrete commitments", in: app)
        XCTAssertTrue(scrollUntilButton("Save weekly review", in: app))
        app.buttons["Save weekly review"].tap()
        XCTAssertTrue(scrollUntilStaticText("Review the V1 acceptance artifact", in: app))
        XCTAssertTrue(scrollUntilStaticText("Finish V1 acceptance", in: app))
        captureScreenshot(named: "Light-review-entry")
    }

    private func assertV1SurfacesRender(interfaceStyle: String) {
        let app = XCUIApplication()
        app.launchEnvironment["CLARITYHUB_IN_MEMORY_STORE"] = "1"
        app.launchEnvironment["CLARITYHUB_HEALTHKIT_FIXTURE"] = "empty"
        app.launchEnvironment["CLARITYHUB_GOOGLE_CALENDAR_FIXTURE"] = "no-token"
        app.launchArguments += ["-AppleInterfaceStyle", interfaceStyle]
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "Tab bar should render in \(interfaceStyle) mode.")

        for title in visibleTabs {
            openVisibleTab(title, in: app)
            assertScreenTitle(title, in: app, interfaceStyle: interfaceStyle)
            assertSetupSection(for: title, in: app, interfaceStyle: interfaceStyle)
            captureScreenshot(named: "\(interfaceStyle)-\(title)-surface")
        }

        for title in moreTabs {
            openMoreTab(title, in: app)
            assertScreenTitle(title, in: app, interfaceStyle: interfaceStyle)
            assertSetupSection(for: title, in: app, interfaceStyle: interfaceStyle)
            captureScreenshot(named: "\(interfaceStyle)-\(title)-surface")
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
        captureScreenshot(named: "\(interfaceStyle)-dense-today")
    }

    private func launchDenseFixture(interfaceStyle: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["CLARITYHUB_IN_MEMORY_STORE"] = "1"
        app.launchEnvironment["CLARITYHUB_UI_TEST_FIXTURE"] = "dense"
        app.launchEnvironment["CLARITYHUB_HEALTHKIT_FIXTURE"] = "empty"
        app.launchEnvironment["CLARITYHUB_GOOGLE_CALENDAR_FIXTURE"] = "no-token"
        app.launchArguments += ["-AppleInterfaceStyle", interfaceStyle]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "Tab bar should render in \(interfaceStyle) mode.")
        return app
    }

    private func launchNutritionImportFixture(interfaceStyle: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["CLARITYHUB_IN_MEMORY_STORE"] = "1"
        app.launchEnvironment["CLARITYHUB_HEALTHKIT_FIXTURE"] = "empty"
        app.launchEnvironment["CLARITYHUB_GOOGLE_CALENDAR_FIXTURE"] = "no-token"
        app.launchEnvironment["CLARITYHUB_NUTRITION_IMPORT_TEXT"] = "Calories 3120 Protein 188 Carbs 355 Fat 91"
        app.launchArguments += ["-AppleInterfaceStyle", interfaceStyle]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "Tab bar should render in \(interfaceStyle) mode.")
        return app
    }

    private func launchBlankFixture(interfaceStyle: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["CLARITYHUB_IN_MEMORY_STORE"] = "1"
        app.launchEnvironment["CLARITYHUB_HEALTHKIT_FIXTURE"] = "empty"
        app.launchEnvironment["CLARITYHUB_GOOGLE_CALENDAR_FIXTURE"] = "no-token"
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

    private func launchGoogleDisconnectedFixture(interfaceStyle: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["CLARITYHUB_IN_MEMORY_STORE"] = "1"
        app.launchEnvironment["CLARITYHUB_HEALTHKIT_FIXTURE"] = "empty"
        app.launchEnvironment["CLARITYHUB_GOOGLE_CALENDAR_FIXTURE"] = "fail-if-called"
        app.launchArguments += ["-AppleInterfaceStyle", interfaceStyle]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "Tab bar should render in \(interfaceStyle) mode.")
        return app
    }

    private func launchReminderFixture(state: String, interfaceStyle: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["CLARITYHUB_IN_MEMORY_STORE"] = "1"
        app.launchEnvironment["CLARITYHUB_HEALTHKIT_FIXTURE"] = "empty"
        app.launchEnvironment["CLARITYHUB_GOOGLE_CALENDAR_FIXTURE"] = "no-token"
        app.launchEnvironment["CLARITYHUB_REMINDER_FIXTURE"] = state
        app.launchArguments += ["-AppleInterfaceStyle", interfaceStyle]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "Tab bar should render in \(interfaceStyle) mode.")
        return app
    }

    private func launchGoogleConnectedFixture(interfaceStyle: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["CLARITYHUB_IN_MEMORY_STORE"] = "1"
        app.launchEnvironment["CLARITYHUB_UI_TEST_FIXTURE"] = "dense"
        app.launchEnvironment["CLARITYHUB_HEALTHKIT_FIXTURE"] = "empty"
        app.launchEnvironment["CLARITYHUB_GOOGLE_CALENDAR_FIXTURE"] = "connected"
        app.launchArguments += ["-AppleInterfaceStyle", interfaceStyle]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "Tab bar should render in \(interfaceStyle) mode.")
        return app
    }

    private func launchPersistentStoreFixture(
        storeName: String,
        seedDenseFixture: Bool,
        interfaceStyle: String
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["CLARITYHUB_PERSISTENT_UI_TEST_STORE"] = "1"
        app.launchEnvironment["CLARITYHUB_STORE_CONFIGURATION_NAME"] = storeName
        app.launchEnvironment["CLARITYHUB_HEALTHKIT_FIXTURE"] = "empty"
        app.launchEnvironment["CLARITYHUB_GOOGLE_CALENDAR_FIXTURE"] = "no-token"
        if seedDenseFixture {
            app.launchEnvironment["CLARITYHUB_UI_TEST_FIXTURE"] = "dense"
        }
        app.launchArguments += ["-AppleInterfaceStyle", interfaceStyle]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10), "Tab bar should render in \(interfaceStyle) mode.")
        return app
    }

    private func openVisibleTab(_ title: String, in app: XCUIApplication) {
        dismissKeyboard(in: app)
        let button = app.tabBars.buttons[title]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "\(title) tab should be visible.")

        let titleElement = app.staticTexts["screenTitle.\(title)"]
        for _ in 0..<3 {
            button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            if titleElement.waitForExistence(timeout: 3) {
                return
            }
            dismissKeyboard(in: app)
        }
    }

    private func openMoreTab(_ title: String, in app: XCUIApplication) {
        dismissKeyboard(in: app)
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
            titleElement.waitForExistence(timeout: 10),
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

    private func scrollUntilStaticText(containing text: String, in app: XCUIApplication) -> Bool {
        let element = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
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

    private func scrollUntilButton(withIdentifier identifier: String, in app: XCUIApplication) -> Bool {
        let button = app.buttons[identifier]
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

    private func scrollUntilButton(containing label: String, in app: XCUIApplication) -> Bool {
        let button = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", label)).firstMatch
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

    private func typeText(_ text: String, intoTextField placeholder: String, in app: XCUIApplication) {
        if !textInputExists(placeholder, in: app, timeout: 2) {
            let scrollView = app.scrollViews.firstMatch
            for _ in 0..<5 where scrollView.exists && !textInput(placeholder, in: app).exists {
                scrollView.swipeUp()
            }
        }
        let input = textInput(placeholder, in: app)
        XCTAssertTrue(input.waitForExistence(timeout: 5), "\(placeholder) field should be available.")
        input.tap()
        input.typeText(text)
        dismissKeyboard(in: app)
    }

    private func textInputExists(_ placeholder: String, in app: XCUIApplication, timeout: TimeInterval) -> Bool {
        app.textFields[placeholder].waitForExistence(timeout: timeout)
            || app.textViews[placeholder].waitForExistence(timeout: timeout)
    }

    private func textInput(_ placeholder: String, in app: XCUIApplication) -> XCUIElement {
        let textField = app.textFields[placeholder]
        if textField.exists {
            return textField
        }
        let textView = app.textViews[placeholder]
        if textView.exists {
            return textView
        }
        return textField
    }

    private func dismissKeyboard(in app: XCUIApplication) {
        guard app.keyboards.firstMatch.exists else { return }
        let doneButton = app.keyboards.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
            return
        }
        let returnButton = app.keyboards.buttons["Return"]
        if returnButton.exists {
            returnButton.tap()
            return
        }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05)).tap()
    }

    private func captureScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "V1 acceptance \(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
