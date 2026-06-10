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
                Rate(currencyCode: "EUR", value: 1.0),
                Rate(currencyCode: "USD", value: 1.1),
                Rate(currencyCode: "GBP", value: 0.86),
                Rate(currencyCode: "JPY", value: 160.0)
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

    // MARK: - Tests: JSON Decoding (API returns rates as strings, not numbers)

    func testDecoding_RatesAsStrings() throws {
        let json = """
        {
            "date": "2026-06-10 00:00:00+00",
            "base": "USD",
            "rates": {
                "EUR": "0.9209",
                "GBP": "0.7911",
                "JPY": "157.25"
            }
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(ExchangeRates.self, from: json)

        XCTAssertEqual(decoded.base, "USD")
        XCTAssertEqual(decoded.date, "2026-06-10 00:00:00+00")
        XCTAssertEqual(decoded.rates.first(where: { $0.currencyCode == "EUR" })?.value ?? 0.0, 0.9209, accuracy: 0.0001)
        XCTAssertEqual(decoded.rates.first(where: { $0.currencyCode == "GBP" })?.value ?? 0.0, 0.7911, accuracy: 0.0001)
        XCTAssertEqual(decoded.rates.first(where: { $0.currencyCode == "JPY" })?.value ?? 0.0, 157.25, accuracy: 0.01)
    }

    func testDecoding_SkipsMalformedRateValues() throws {
        let json = """
        {
            "base": "USD",
            "rates": {
                "EUR": "0.92",
                "BAD": "not-a-number"
            }
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(ExchangeRates.self, from: json)

        XCTAssertNotNil(decoded.rates.first(where: { $0.currencyCode == "EUR" }))
        XCTAssertNil(decoded.rates.first(where: { $0.currencyCode == "BAD" }))
    }
}

// Helper for comparing floating point numbers
extension XCTestCase {
    func XCTAssertAlmostEqual(_ expression1: Double, _ expression2: Double, accuracy: Double, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(abs(expression1 - expression2) <= accuracy, message(), file: file, line: line)
    }
}
