//
//  CurrencyExchangeExamUITests.swift
//  CurrencyExchangeExamUITests
//
//  Created by Macintosh HD on 6/10/26.
//
//  End-to-end UI tests for the full currency exchange flow:
//  Balances screen → Balance detail → Exchange modal → Confirm/Cancel

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

    // MARK: - Navigation Helpers

    /// Navigates from the Balances screen into the Exchange modal for USD.
    /// The flow is: tap "US Dollar" card → tap "Exchange Currency" button.
    private func navigateToExchangeModal() {
        let usdCard = app.staticTexts["US Dollar"].firstMatch
        XCTAssertTrue(usdCard.waitForExistence(timeout: 5), "USD balance card should appear on launch")
        usdCard.tap()

        let exchangeBtn = app.buttons["Exchange Currency"].firstMatch
        XCTAssertTrue(exchangeBtn.waitForExistence(timeout: 3), "Exchange Currency button should appear on detail screen")
        exchangeBtn.tap()
    }

    /// Taps numpad buttons by their accessibility identifier.
    private func enterAmount(_ digits: [String]) {
        for digit in digits {
            app.buttons[digit].firstMatch.tap()
        }
    }

    /// Taps the "Exchange" submit button inside the exchange modal.
    private func tapExchangeButton() {
        app.buttons["Exchange"].firstMatch.tap()
    }

    /// Taps the close (✕) button in the "Currency Exchange" modal's navigation bar.
    private func closeExchangeModal() {
        app.navigationBars["Currency Exchange"].buttons.firstMatch.tap()
    }

    // MARK: - Confirmation Alert Appearance

    func testConfirmationAlertAppearsAfterTappingExchange() {
        navigateToExchangeModal()
        enterAmount(["1", "0", "0"])
        tapExchangeButton()

        XCTAssertTrue(
            app.alerts["Confirm Exchange"].waitForExistence(timeout: 5),
            "Confirmation alert should appear after tapping Exchange"
        )
    }

    func testConfirmationAlertShowsCancelAndConfirmButtons() {
        navigateToExchangeModal()
        enterAmount(["5", "0"])
        tapExchangeButton()

        let alert = app.alerts["Confirm Exchange"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.buttons["Cancel"].exists)
        XCTAssertTrue(alert.buttons["Confirm"].exists)
    }

    func testConfirmationAlertMessageContainsSellInfo() {
        navigateToExchangeModal()
        enterAmount(["1", "0", "0"])
        tapExchangeButton()

        let alert = app.alerts["Confirm Exchange"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))

        let sellLabel = alert.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'Sell:'")
        ).firstMatch
        XCTAssertTrue(sellLabel.exists, "Alert message should contain 'Sell:' text")

        let commissionLabel = alert.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'Commission fee:'")
        ).firstMatch
        XCTAssertTrue(commissionLabel.exists, "Alert message should contain 'Commission fee:' text")
    }

    // MARK: - Cancel Path

    func testCancelDismissesConfirmationAlert() {
        navigateToExchangeModal()
        enterAmount(["2", "0", "0"])
        tapExchangeButton()

        let alert = app.alerts["Confirm Exchange"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Cancel"].tap()

        XCTAssertFalse(alert.exists, "Alert should be dismissed after tapping Cancel")
    }

    func testCancelDoesNotChangeBalance() {
        navigateToExchangeModal()
        enterAmount(["5", "0"])
        tapExchangeButton()

        app.alerts["Confirm Exchange"].waitForExistence(timeout: 5)
        app.alerts["Confirm Exchange"].buttons["Cancel"].tap()

        // Close the exchange modal to return to the detail screen
        closeExchangeModal()

        // Balance on the detail screen should remain 1,000.00
        let balanceLabel = app.staticTexts.matching(
            NSPredicate(format: "label == '1,000.00'")
        ).firstMatch
        XCTAssertTrue(
            balanceLabel.waitForExistence(timeout: 3),
            "Balance should be unchanged (1,000.00) after cancelling"
        )
    }

    // MARK: - Confirm Path

    func testConfirmShowsSuccessAlert() {
        navigateToExchangeModal()
        enterAmount(["1", "0", "0"])
        tapExchangeButton()

        let confirmAlert = app.alerts["Confirm Exchange"]
        XCTAssertTrue(confirmAlert.waitForExistence(timeout: 5))
        confirmAlert.buttons["Confirm"].tap()

        XCTAssertTrue(
            app.alerts["Exchange Successful"].waitForExistence(timeout: 7),
            "Success alert should appear after confirming exchange"
        )
    }

    func testConfirmSuccessAlertShowsOKButton() {
        navigateToExchangeModal()
        enterAmount(["5", "0"])
        tapExchangeButton()

        app.alerts["Confirm Exchange"].waitForExistence(timeout: 5)
        app.alerts["Confirm Exchange"].buttons["Confirm"].tap()

        let successAlert = app.alerts["Exchange Successful"]
        XCTAssertTrue(successAlert.waitForExistence(timeout: 7))
        XCTAssertTrue(successAlert.buttons["OK"].exists)
        successAlert.buttons["OK"].tap()
    }

    // MARK: - Invalid Amount Guard

    func testExchangeWithZeroAmountShowsInvalidAlert() {
        navigateToExchangeModal()
        // Default amount is already "0" — tap Exchange without entering any digits
        tapExchangeButton()

        XCTAssertTrue(
            app.alerts["Invalid Amount"].waitForExistence(timeout: 3),
            "Invalid amount alert should appear when no amount is entered"
        )
    }
}
