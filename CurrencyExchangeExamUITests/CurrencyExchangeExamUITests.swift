//
//  CurrencyExchangeExamUITests.swift
//  CurrencyExchangeExamUITests
//
//  Created by Macintosh HD on 6/10/26.
//

import XCTest

final class CurrencyExchangeExamUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    private func enterAmount(_ digits: [String]) {
        for digit in digits {
            app.buttons[digit].firstMatch.tap()
        }
    }

    private func tapExchangeButton() {
        app.buttons["Exchange"].firstMatch.tap()
    }

    // MARK: - Confirmation Alert Appearance

    func testConfirmationAlertAppearsAfterTappingExchange() {
        enterAmount(["1", "0", "0"])
        tapExchangeButton()

        let alert = app.alerts["Confirm Exchange"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3), "Confirmation alert should appear")
    }

    func testConfirmationAlertShowsCancelAndConfirmButtons() {
        enterAmount(["5", "0"])
        tapExchangeButton()

        let alert = app.alerts["Confirm Exchange"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        XCTAssertTrue(alert.buttons["Cancel"].exists)
        XCTAssertTrue(alert.buttons["Confirm"].exists)
    }

    func testConfirmationAlertMessageContainsSellInfo() {
        enterAmount(["1", "0", "0"])
        tapExchangeButton()

        let alert = app.alerts["Confirm Exchange"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        XCTAssertTrue(alert.staticTexts.element.label.contains("Sell:"))
        XCTAssertTrue(alert.staticTexts.element.label.contains("Commission fee:"))
    }

    // MARK: - Cancel Path

    func testCancelDismissesConfirmationAlert() {
        enterAmount(["2", "0", "0"])
        tapExchangeButton()

        let alert = app.alerts["Confirm Exchange"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))

        alert.buttons["Cancel"].tap()

        XCTAssertFalse(alert.exists, "Alert should be dismissed after tapping Cancel")
    }

    func testCancelDoesNotChangeBalance() {
        let initialBalance = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'USD'")).firstMatch.label

        enterAmount(["5", "0"])
        tapExchangeButton()
        app.alerts["Confirm Exchange"].buttons["Cancel"].tap()

        let balanceAfterCancel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'USD'")).firstMatch.label
        XCTAssertEqual(initialBalance, balanceAfterCancel, "Balance should not change after cancelling")
    }

    // MARK: - Confirm Path

    func testConfirmShowsSuccessAlert() {
        enterAmount(["1", "0", "0"])
        tapExchangeButton()

        let confirmationAlert = app.alerts["Confirm Exchange"]
        XCTAssertTrue(confirmationAlert.waitForExistence(timeout: 3))
        confirmationAlert.buttons["Confirm"].tap()

        let successAlert = app.alerts["Exchange Successful"]
        XCTAssertTrue(successAlert.waitForExistence(timeout: 5), "Success alert should appear after confirming exchange")
    }

    func testConfirmSuccessAlertShowsOKButton() {
        enterAmount(["5", "0"])
        tapExchangeButton()

        app.alerts["Confirm Exchange"].waitForExistence(timeout: 3)
        app.alerts["Confirm Exchange"].buttons["Confirm"].tap()

        let successAlert = app.alerts["Exchange Successful"]
        XCTAssertTrue(successAlert.waitForExistence(timeout: 5))
        XCTAssertTrue(successAlert.buttons["OK"].exists)
        successAlert.buttons["OK"].tap()
    }

    // MARK: - Invalid Amount Guard

    func testExchangeWithZeroAmountShowsInvalidAlert() {
        // Default state has "0" — tap Exchange without entering anything
        tapExchangeButton()

        let invalidAlert = app.alerts["Invalid Amount"]
        XCTAssertTrue(invalidAlert.waitForExistence(timeout: 3), "Invalid amount alert should appear for zero input")
    }
}
