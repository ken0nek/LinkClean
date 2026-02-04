//
//  LinkCleanUITests.swift
//  LinkCleanUITests
//
//  Created by Ken Tominaga on 2/1/26.
//

import XCTest

final class LinkCleanUITests: XCTestCase {

    @MainActor
    func testAutoPasteToggleDefaultsOnAndToggles() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        dismissPastePermissionIfNeeded()

        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 2))
        settingsTab.tap()

        let toggleContainer = app.switches["settings-auto-paste-toggle"]
        XCTAssertTrue(toggleContainer.waitForExistence(timeout: 2))

        // SwiftUI Forms can expose a "switch container" element. The real UISwitch is often a nested descendant.
        let toggle = toggleContainer.switches.firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 2))
        XCTAssertEqual(toggle.value as? String, "1")

        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "0")
    }

    @MainActor
    private func dismissPastePermissionIfNeeded() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        guard alert.waitForExistence(timeout: 0.8) else { return }

        // Clipboard permission alert has 2 buttons: top is "Don't Allow", bottom is "Allow".
        // Use index to avoid localization issues.
        let allowButton = alert.buttons.element(boundBy: 1)
        if allowButton.exists {
            allowButton.tap()
        }
    }
}
