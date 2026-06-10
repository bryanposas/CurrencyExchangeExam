//
//  AccountTests.swift
//  CurrencyExchangeExamTests
//
//  Created by Macintosh HD on 6/10/26.
//

import XCTest
@testable import CurrencyExchangeExam

final class AccountTests: XCTestCase {
    
    var sut: Account!
    
    override func setUp() {
        super.setUp()
        sut = Account()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Tests: Balance Retrieval
    
    func testGetBalance_WithExistingCurrency() {
        sut.setBalance(500, for: "EUR")
        let balance = sut.getBalance(for: "EUR")
        XCTAssertEqual(balance, 500)
    }
    
    func testGetBalance_WithNonExistentCurrency() {
        let balance = sut.getBalance(for: "USD")
        XCTAssertEqual(balance, 0)
    }
    
    // MARK: - Tests: Balance Setting
    
    func testSetBalance_NewCurrency() {
        sut.setBalance(1000, for: "EUR")
        XCTAssertEqual(sut.balances["EUR"], 1000)
    }
    
    func testSetBalance_UpdateExisting() {
        sut.setBalance(1000, for: "EUR")
        sut.setBalance(500, for: "EUR")
        XCTAssertEqual(sut.balances["EUR"], 500)
    }
    
    // MARK: - Tests: Exchange Validation
    
    func testCanExchange_WithSufficientFunds() {
        sut.setBalance(1000, for: "EUR")
        let result = sut.canExchange(amount: 500, from: "EUR")
        XCTAssertTrue(result)
    }
    
    func testCanExchange_WithInsufficientFunds() {
        sut.setBalance(100, for: "EUR")
        let result = sut.canExchange(amount: 500, from: "EUR")
        XCTAssertFalse(result)
    }
    
    func testCanExchange_WithZeroAmount() {
        sut.setBalance(1000, for: "EUR")
        let result = sut.canExchange(amount: 0, from: "EUR")
        XCTAssertFalse(result)
    }
    
    func testCanExchange_WithNegativeAmount() {
        sut.setBalance(1000, for: "EUR")
        let result = sut.canExchange(amount: -100, from: "EUR")
        XCTAssertFalse(result)
    }
    
    func testCanExchange_WithNonExistentCurrency() {
        let result = sut.canExchange(amount: 100, from: "USD")
        XCTAssertFalse(result)
    }
}
