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
    
    func testInitializationWithEURBalance() {
        let balance = sut.getBalance(for: "EUR")
        XCTAssertEqual(balance, 1000)
    }
    
    // MARK: - Tests: Exchange Validation
    
    func testExchangeFailsWithInvalidAmount() {
        let result = sut.exchange(amount: 0, from: "EUR", to: "USD")
        
        if case .failure(let error) = result {
            XCTAssertEqual(error as? AppError, .invalidAmount)
        } else {
            XCTFail("Expected failure")
        }
    }
    
    func testExchangeFailsWithSameCurrency() {
        let result = sut.exchange(amount: 100, from: "EUR", to: "EUR")
        
        if case .failure(let error) = result {
            XCTAssertEqual(error as? AppError, .sameCurrency)
        } else {
            XCTFail("Expected failure")
        }
    }
    
    func testExchangeFailsWithInsufficientFunds() {
        let result = sut.exchange(amount: 2000, from: "EUR", to: "USD")
        
        if case .failure(let error) = result {
            XCTAssertEqual(error as? AppError, .insufficientFunds)
        } else {
            XCTFail("Expected failure")
        }
    }
    
    func testExchangeFailsWithMissingRates() {
        let result = sut.exchange(amount: 100, from: "EUR", to: "USD")
        
        if case .failure(let error) = result {
            XCTAssertEqual(error as? AppError, .invalidExchangeRate)
        } else {
            XCTFail("Expected failure")
        }
    }
    
    // MARK: - Tests: Successful Exchange
    
    func testSuccessfulExchange() {
        // Set up rates
        let rates = ExchangeRates(
            base: "EUR",
            rates: ["EUR": 1.0, "USD": 1.1],
            date: nil
        )
        sut.exchangeRates = rates
        
        let result = sut.exchange(amount: 100, from: "EUR", to: "USD")
        
        switch result {
        case .success(let transaction):
            XCTAssertEqual(transaction.fromCurrency, "EUR")
            XCTAssertEqual(transaction.toCurrency, "USD")
            XCTAssertEqual(transaction.fromAmount, 100)
            XCTAssertEqual(transaction.toAmount, 110)
            XCTAssertEqual(transaction.exchangeRate, 1.1)
        case .failure:
            XCTFail("Expected success")
        }
    }
    
    func testBalanceUpdatedAfterExchange() {
        let rates = ExchangeRates(
            base: "EUR",
            rates: ["EUR": 1.0, "USD": 1.1],
            date: nil
        )
        sut.exchangeRates = rates
        
        _ = sut.exchange(amount: 100, from: "EUR", to: "USD")
        
        XCTAssertEqual(sut.getBalance(for: "EUR"), 900)
        XCTAssertEqual(sut.getBalance(for: "USD"), 110)
    }
    
    func testTransactionHistoryRecorded() {
        let rates = ExchangeRates(
            base: "EUR",
            rates: ["EUR": 1.0, "USD": 1.1],
            date: nil
        )
        sut.exchangeRates = rates
        
        _ = sut.exchange(amount: 100, from: "EUR", to: "USD")
        
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

// Extension to allow setting exchangeRates for testing
extension CurrencyExchangeManager {
    var exchangeRates: ExchangeRates? {
        get { return nil }
        set { }
    }
}
