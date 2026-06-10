//
//  CoreDataPersistenceServiceTests.swift
//  CurrencyExchangeExamTests
//
//  Created by Automated Agent on 6/10/26.
//

import XCTest
@testable import CurrencyExchangeExam

final class CoreDataPersistenceServiceTests: XCTestCase {
    var sut: CoreDataPersistenceService!

    override func setUp() {
        super.setUp()
        // in-memory store for tests
        sut = CoreDataPersistenceService(storeName: "TestModel", inMemory: true)
        sut.clearAll()
    }

    override func tearDown() {
        sut.clearAll()
        sut = nil
        super.tearDown()
    }

    func testSaveAndLoadBalances() throws {
        let balances: [String: Double] = ["EUR": 1000.0, "USD": 300.5]
        try sut.saveBalances(balances)

        let loaded = sut.loadBalances()
        XCTAssertEqual(loaded.count, balances.count)
        XCTAssertEqual(loaded["EUR"], 1000.0)
        XCTAssertEqual(loaded["USD"], 300.5)
    }

    func testSaveAndLoadTransactions() throws {
        let tx = ExchangeTransaction(fromCurrency: "EUR", toCurrency: "USD", fromAmount: 100, toAmount: 110, exchangeRate: 1.1, timestamp: Date(), commissionAmount: 1.0)
        try sut.saveTransactionHistory([tx])

        let history = sut.loadTransactionHistory()
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history[0].fromCurrency, "EUR")
        XCTAssertEqual(history[0].toCurrency, "USD")
        XCTAssertEqual(history[0].commissionAmount, 1.0)
    }

    func testClearAllRemovesData() throws {
        try sut.saveBalances(["EUR": 1])
        try sut.saveTransactionHistory([ExchangeTransaction(fromCurrency: "EUR", toCurrency: "USD", fromAmount: 1, toAmount: 1, exchangeRate: 1, timestamp: Date(), commissionAmount: 0)])

        sut.clearAll()

        XCTAssertTrue(sut.loadBalances().isEmpty)
        XCTAssertTrue(sut.loadTransactionHistory().isEmpty)
    }
}
