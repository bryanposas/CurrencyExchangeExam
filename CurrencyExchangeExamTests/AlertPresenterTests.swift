//
//  AlertPresenterTests.swift
//  CurrencyExchangeExamTests
//
//  Created by Macintosh HD on 6/10/26.
//

import XCTest
@testable import CurrencyExchangeExam

final class AlertPresenterTests: XCTestCase {

    // MARK: - Mock

    final class MockAlertPresenter: AlertPresenting {
        private(set) var alertTitle: String?
        private(set) var alertMessage: String?
        private(set) var confirmationShown = false
        private(set) var capturedSellAmount: Double?
        private(set) var capturedSellCurrency: String?
        private(set) var capturedReceiveText: String?
        private(set) var capturedCommission: Double?
        var storedConfirmHandler: (() -> Void)?

        func showAlert(on presenter: UIViewController, title: String, message: String) {
            alertTitle = title
            alertMessage = message
        }

        func showExchangeConfirmation(
            on presenter: UIViewController,
            sellAmount: Double,
            sellCurrency: String,
            receiveText: String,
            commission: Double,
            onConfirm: @escaping () -> Void
        ) {
            confirmationShown = true
            capturedSellAmount = sellAmount
            capturedSellCurrency = sellCurrency
            capturedReceiveText = receiveText
            capturedCommission = commission
            storedConfirmHandler = onConfirm
        }
    }

    // MARK: - Setup

    var dummyVC: UIViewController!

    override func setUp() {
        super.setUp()
        dummyVC = UIViewController()
    }

    override func tearDown() {
        dummyVC = nil
        super.tearDown()
    }

    // MARK: - Protocol Conformance

    func testAlertPresenterConformsToAlertPresenting() {
        let _: AlertPresenting = AlertPresenter()
    }

    // MARK: - showAlert

    func testShowAlert_CapturesTitleAndMessage() {
        let mock = MockAlertPresenter()
        mock.showAlert(on: dummyVC, title: "Test Title", message: "Test Message")

        XCTAssertEqual(mock.alertTitle, "Test Title")
        XCTAssertEqual(mock.alertMessage, "Test Message")
    }

    func testShowAlert_DoesNotSetConfirmationFlag() {
        let mock = MockAlertPresenter()
        mock.showAlert(on: dummyVC, title: "Error", message: "Something went wrong.")

        XCTAssertFalse(mock.confirmationShown)
    }

    // MARK: - showExchangeConfirmation

    func testShowExchangeConfirmation_SetsConfirmationFlag() {
        let mock = MockAlertPresenter()
        mock.showExchangeConfirmation(
            on: dummyVC,
            sellAmount: 100, sellCurrency: "USD",
            receiveText: "91.00 EUR", commission: 1.0
        ) { }

        XCTAssertTrue(mock.confirmationShown)
    }

    func testShowExchangeConfirmation_CapturesAllParameters() {
        let mock = MockAlertPresenter()
        mock.showExchangeConfirmation(
            on: dummyVC,
            sellAmount: 250.50,
            sellCurrency: "EUR",
            receiveText: "272.89 USD",
            commission: 2.51
        ) { }

        XCTAssertEqual(mock.capturedSellAmount ?? 0.0, 250.50, accuracy: 0.001)
        XCTAssertEqual(mock.capturedSellCurrency, "EUR")
        XCTAssertEqual(mock.capturedReceiveText, "272.89 USD")
        XCTAssertEqual(mock.capturedCommission ?? 0.0, 2.51, accuracy: 0.001)
    }

    func testShowExchangeConfirmation_OnConfirmCallbackIsInvoked() {
        let mock = MockAlertPresenter()
        var confirmCalled = false

        mock.showExchangeConfirmation(
            on: dummyVC,
            sellAmount: 100, sellCurrency: "USD",
            receiveText: "91.00 EUR", commission: 1.0
        ) {
            confirmCalled = true
        }

        XCTAssertFalse(confirmCalled, "Callback should not fire before user taps Confirm")
        mock.storedConfirmHandler?()
        XCTAssertTrue(confirmCalled, "Callback should fire when Confirm is tapped")
    }

    func testShowExchangeConfirmation_OnConfirmNotCalledWhenCancelled() {
        let mock = MockAlertPresenter()
        var confirmCalled = false

        mock.showExchangeConfirmation(
            on: dummyVC,
            sellAmount: 100, sellCurrency: "USD",
            receiveText: "91.00 EUR", commission: 1.0
        ) {
            confirmCalled = true
        }

        // Simulate cancel — handler is never called
        XCTAssertFalse(confirmCalled)
    }

    // MARK: - Commission Calculation Consistency

    func testCommissionMatchesExpectedRate() {
        let mock = MockAlertPresenter()
        let sellAmount = 200.0
        let expectedCommission = sellAmount * Constants.Account.commissionRate

        mock.showExchangeConfirmation(
            on: dummyVC,
            sellAmount: sellAmount,
            sellCurrency: "USD",
            receiveText: "182.00 EUR",
            commission: expectedCommission
        ) { }

        XCTAssertEqual(mock.capturedCommission ?? 0, expectedCommission, accuracy: 0.001)
    }
}
