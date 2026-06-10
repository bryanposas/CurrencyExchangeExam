//
//  ExchangeRatesTests.swift
//  CurrencyExchangeExamTests
//
//  Created by Macintosh HD on 6/10/26.
//

import XCTest
@testable import CurrencyExchangeExam

final class ExchangeRatesTests: XCTestCase {
    
    var sut: ExchangeRates!
    
    override func setUp() {
        super.setUp()
        sut = ExchangeRates(
            base: "EUR",
            rates: [
                "EUR": 1.0,
                "USD": 1.1,
                "GBP": 0.86,
                "JPY": 160.0
            ],
            date: nil
        )
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Tests: Exchange Rate Calculation
    
    func testGetRate_SameCurrency() {
        let rate = sut.getRate(from: "EUR", to: "EUR")
        XCTAssertEqual(rate, 1.0)
    }
    
    func testGetRate_ValidCurrencies() {
        let rate = sut.getRate(from: "EUR", to: "USD")
        XCTAssertEqual(rate, 1.1)
    }
    
    func testGetRate_ReverseConversion() {
        let rate = sut.getRate(from: "USD", to: "EUR")
        XCTAssertNotNil(rate)
        if let rate = rate {
            XCTAssertAlmostEqual(rate, 1.0 / 1.1, accuracy: 0.001)
        }
    }
    
    func testGetRate_MissingSourceCurrency() {
        let rate = sut.getRate(from: "XXX", to: "USD")
        XCTAssertNil(rate)
    }
    
    func testGetRate_MissingTargetCurrency() {
        let rate = sut.getRate(from: "EUR", to: "XXX")
        XCTAssertNil(rate)
    }
    
    func testGetRate_ComplexConversion() {
        let rate = sut.getRate(from: "GBP", to: "JPY")
        XCTAssertNotNil(rate)
        if let rate = rate {
            let expected = 160.0 / 0.86
            XCTAssertAlmostEqual(rate, expected, accuracy: 0.01)
        }
    }
}

// Helper for comparing floating point numbers
extension XCTestCase {
    func XCTAssertAlmostEqual(_ expression1: Double, _ expression2: Double, accuracy: Double, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(abs(expression1 - expression2) <= accuracy, message(), file: file, line: line)
    }
}
