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
    var mockPersistenceService: MockPersistenceService!
    
    override func setUp() {
        super.setUp()
        mockRateService = MockExchangeRateService()
        mockPersistenceService = MockPersistenceService()
        sut = CurrencyExchangeManager(rateService: mockRateService, persistenceService: mockPersistenceService)
    }
    
    override func tearDown() {
        sut = nil
        mockRateService = nil
        mockPersistenceService = nil
        super.tearDown()
    }
    
    // MARK: - Tests: Initialization
    
    func testInitializationWithDefaultBalance() {
        let balance = sut.getBalance(for: Constants.Account.initialFromCurrency)
        XCTAssertEqual(balance, Constants.Account.initialBalance)
    }
    
    func testInitializationSavesInitialBalance() throws {
        // The mock should have recorded the save
        let savedBalances = mockPersistenceService.savedBalances
        XCTAssertNotNil(savedBalances)
        XCTAssertEqual(savedBalances?[Constants.Account.initialFromCurrency], Constants.Account.initialBalance)
    }
    
    func testInitializationLoadsPersistedBalances() {
        // Create a new persistence service with pre-loaded balances
        let persistenceWithData = MockPersistenceService()
        persistenceWithData.balancesToReturn = ["EUR": 500, "USD": 250]
        
        let manager = CurrencyExchangeManager(rateService: mockRateService, persistenceService: persistenceWithData)
        
        XCTAssertEqual(manager.getBalance(for: "EUR"), 500)
        XCTAssertEqual(manager.getBalance(for: "USD"), 250)
    }
    
    // MARK: - Tests: Exchange Validation
    
    func testExchangeFailsWithInvalidAmount() {
        let result = sut.exchange(amount: 0, from: Constants.Account.initialFromCurrency, to: "EUR")
        
        if case .failure(let error) = result {
            XCTAssertEqual(error as? AppError, .invalidAmount)
        } else {
            XCTFail("Expected failure")
        }
    }
    
    func testExchangeFailsWithSameCurrency() {
        let result = sut.exchange(amount: 100, from: Constants.Account.initialFromCurrency, to: Constants.Account.initialFromCurrency)
        
        if case .failure(let error) = result {
            XCTAssertEqual(error as? AppError, .sameCurrency)
        } else {
            XCTFail("Expected failure")
        }
    }
    
    func testExchangeFailsWithInsufficientFunds() {
        let result = sut.exchange(amount: 2000, from: Constants.Account.initialFromCurrency, to: "EUR")
        
        if case .failure(let error) = result {
            XCTAssertEqual(error as? AppError, .insufficientFunds)
        } else {
            XCTFail("Expected failure")
        }
    }
    
    func testExchangeFailsWithMissingRates() {
        let result = sut.exchange(amount: 100, from: Constants.Account.initialFromCurrency, to: "EUR")
        
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
            base: Constants.Account.initialFromCurrency,
            rates: [Rate(currencyCode: Constants.Account.initialFromCurrency, value: 1.0), Rate(currencyCode: "EUR", value: 0.92)],
            date: nil
        )
        sut.exchangeRates = rates
        
        let result = sut.exchange(amount: 100, from: Constants.Account.initialFromCurrency, to: "EUR")
        
        switch result {
        case .success(let transaction):
            XCTAssertEqual(transaction.fromCurrency, Constants.Account.initialFromCurrency)
            XCTAssertEqual(transaction.toCurrency, "EUR")
            XCTAssertEqual(transaction.fromAmount, 100)
            XCTAssertEqual(transaction.commissionAmount, 1.0) // 1% of 100
            XCTAssertEqual(transaction.toAmount, 92) // 100 * 0.92
        case .failure:
            XCTFail("Expected success")
        }
    }
    
    func testBalanceUpdatedAfterExchangeIncludingCommission() {
        let rates = ExchangeRates(
            base: Constants.Account.initialFromCurrency,
            rates: [Rate(currencyCode: Constants.Account.initialFromCurrency, value: 1.0), Rate(currencyCode: "EUR", value: 0.92)],
            date: nil
        )
        sut.exchangeRates = rates
        
        _ = sut.exchange(amount: 100, from: Constants.Account.initialFromCurrency, to: "EUR")
        
        // 1000 - 100 (amount) - 1 (commission) = 899
        XCTAssertEqual(sut.getBalance(for: Constants.Account.initialFromCurrency), 899)
        // 100 * 0.92 = 92
        XCTAssertEqual(sut.getBalance(for: "EUR"), 92)
    }
    
    func testTransactionHistoryRecorded() {
        let rates = ExchangeRates(
            base: Constants.Account.initialFromCurrency,
            rates: [Rate(currencyCode: Constants.Account.initialFromCurrency, value: 1.0), Rate(currencyCode: "EUR", value: 0.92)],
            date: nil
        )
        sut.exchangeRates = rates
        
        _ = sut.exchange(amount: 100, from: Constants.Account.initialFromCurrency, to: "EUR")
        
        let history = sut.getTransactionHistory()
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history[0].fromAmount, 100)
        XCTAssertEqual(history[0].commissionAmount, 1.0)
    }
    
    func testExchangePersistsData() throws {
        let rates = ExchangeRates(
            base: Constants.Account.initialFromCurrency,
            rates: [Rate(currencyCode: Constants.Account.initialFromCurrency, value: 1.0), Rate(currencyCode: "EUR", value: 0.92)],
            date: nil
        )
        sut.exchangeRates = rates
        
        _ = sut.exchange(amount: 100, from: Constants.Account.initialFromCurrency, to: "EUR")
        
        // Verify balances were persisted
        XCTAssertNotNil(mockPersistenceService.savedBalances)
        XCTAssertEqual(mockPersistenceService.savedBalances?[Constants.Account.initialFromCurrency], 899)
        XCTAssertEqual(mockPersistenceService.savedBalances?["EUR"], 92)
        
        // Verify transaction was persisted
        XCTAssertNotNil(mockPersistenceService.savedTransactions)
        XCTAssertEqual(mockPersistenceService.savedTransactions?.count, 1)
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

// MARK: - Mock Persistence Service

/// Mock persistence service for testing that tracks save operations
final class MockPersistenceService: PersistenceProtocol {
    var balancesToReturn: [String: Double] = [:]
    var transactionsToReturn: [ExchangeTransaction] = []
    
    var savedBalances: [String: Double]?
    var savedTransactions: [ExchangeTransaction]?
    var clearAllCalled = false
    
    func saveBalances(_ balances: [String: Double]) throws {
        self.savedBalances = balances
    }
    
    func loadBalances() -> [String: Double] {
        return balancesToReturn
    }
    
    func saveTransactionHistory(_ transactions: [ExchangeTransaction]) throws {
        self.savedTransactions = transactions
    }
    
    func loadTransactionHistory() -> [ExchangeTransaction] {
        return transactionsToReturn
    }
    
    func clearAll() {
        clearAllCalled = true
        balancesToReturn = [:]
        transactionsToReturn = []
    }
}
