//
//  CurrencyExchangeManagerTests.swift
//  CurrencyExchangeExamTests
//
//  Created by Macintosh HD on 6/10/26.
//

import XCTest
@testable import CurrencyExchangeExam

final class CurrencyExchangeManagerTests: XCTestCase {
    
    var sut: CurrencyExchangeManager!
    var mockRateService: MockExchangeRateService!
    
    override func setUp() {
        super.setUp()
        mockRateService = MockExchangeRateService()
        sut = CurrencyExchangeManager(rateService: mockRateService)
    }
    
    override func tearDown() {
        sut = nil
        mockRateService = nil
        super.tearDown()
    }
    
    // MARK: - Tests: Initialization
    
    func testInitializationWithUSDBalance() {
        let balance = sut.getBalance(for: "USD")
        XCTAssertEqual(balance, 1000)
    }
    
    // MARK: - Tests: Exchange Validation
    
    func testExchangeFailsWithInvalidAmount() {
        let result = sut.exchange(amount: 0, from: "USD", to: "EUR")

        if case .failure(let error) = result {
            XCTAssertEqual(error as? AppError, .invalidAmount)
        } else {
            XCTFail("Expected failure")
        }
    }

    func testExchangeFailsWithSameCurrency() {
        let result = sut.exchange(amount: 100, from: "USD", to: "USD")

        if case .failure(let error) = result {
            XCTAssertEqual(error as? AppError, .sameCurrency)
        } else {
            XCTFail("Expected failure")
        }
    }

    func testExchangeFailsWithInsufficientFunds() {
        let result = sut.exchange(amount: 2000, from: "USD", to: "EUR")

        if case .failure(let error) = result {
            XCTAssertEqual(error as? AppError, .insufficientFunds)
        } else {
            XCTFail("Expected failure")
        }
    }

    func testExchangeFailsWithMissingRates() {
        // USD has 1000 balance, so the insufficient-funds check passes and we reach the rates check
        let result = sut.exchange(amount: 100, from: "USD", to: "EUR")

        if case .failure(let error) = result {
            XCTAssertEqual(error as? AppError, .invalidExchangeRate)
        } else {
            XCTFail("Expected failure")
        }
    }
    
    // MARK: - Tests: Successful Exchange
    
    func testSuccessfulExchange() {
        let rates = ExchangeRates(
            base: "USD",
            rates: [Rate(currencyCode: "USD", value: 1.0), Rate(currencyCode: "EUR", value: 0.91)],
            date: nil
        )
        sut.exchangeRates = rates

        let result = sut.exchange(amount: 100, from: "USD", to: "EUR")

        switch result {
        case .success(let transaction):
            XCTAssertEqual(transaction.fromCurrency, "USD")
            XCTAssertEqual(transaction.toCurrency, "EUR")
            XCTAssertEqual(transaction.fromAmount, 100)
            XCTAssertEqual(transaction.toAmount, 91, accuracy: 0.01)
            XCTAssertEqual(transaction.exchangeRate, 0.91, accuracy: 0.0001)
            XCTAssertEqual(transaction.commissionAmount, 1.0, accuracy: 0.001) // 1% of 100
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testBalanceUpdatedAfterExchange() {
        let rates = ExchangeRates(
            base: "USD",
            rates: [Rate(currencyCode: "USD", value: 1.0), Rate(currencyCode: "EUR", value: 0.91)],
            date: nil
        )
        sut.exchangeRates = rates

        _ = sut.exchange(amount: 100, from: "USD", to: "EUR")

        // 100 sold + 1 commission (1%) deducted from USD; 100 * 0.91 = 91 received in EUR
        XCTAssertEqual(sut.getBalance(for: "USD"), 899, accuracy: 0.01)
        XCTAssertEqual(sut.getBalance(for: "EUR"), 91, accuracy: 0.01)
    }

    func testTransactionHistoryRecorded() {
        let rates = ExchangeRates(
            base: "USD",
            rates: [Rate(currencyCode: "USD", value: 1.0), Rate(currencyCode: "EUR", value: 0.91)],
            date: nil
        )
        sut.exchangeRates = rates

        _ = sut.exchange(amount: 100, from: "USD", to: "EUR")
        
        let history = sut.getTransactionHistory()
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history[0].fromAmount, 100)
    }
}

// MARK: - Mock Service
final class MockExchangeRateService: ExchangeRateService {
    var mockRates: ExchangeRates?
    var shouldFail = false
    
    override func fetchExchangeRates(completion: @escaping (Result<ExchangeRates, AppError>) -> Void) {
        if shouldFail {
            completion(.failure(.networkError(NSError(domain: "Mock", code: -1))))
        } else if let rates = mockRates {
            completion(.success(rates))
        }
    }
}

