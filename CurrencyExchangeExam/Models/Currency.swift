//
//  Currency.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import Foundation

/// Represents a single currency balance entry in the user's account
struct CurrencyBalance: Codable {
    let code: String
    var balance: Double
    
    init(code: String, balance: Double = 0) {
        self.code = code
        self.balance = balance
    }
}

/// Represents the user's multi-currency account
struct Account: Codable {
    var balances: [String: Double] = [:]
    
    /// Get balance for a specific currency
    func getBalance(for currencyCode: String) -> Double {
        return balances[currencyCode] ?? 0
    }
    
    /// Update balance for a currency
    mutating func setBalance(_ amount: Double, for currencyCode: String) {
        balances[currencyCode] = amount
    }
    
    /// Check if sufficient funds exist for exchange
    func canExchange(amount: Double, from currency: String) -> Bool {
        let currentBalance = getBalance(for: currency)
        return currentBalance >= amount && amount > 0
    }
}

/**
 {
   "date": "2026-06-10 00:00:00+00",
   "base": "USD",
   "rates": {
     "AGLD": "5.509641873278237",
     "FJD": "2.23339",
     "SCR": "14.6038",
     "BBD": "2.0",
     "HNL": "26.6992",
    }
 }
 */
/// Represents exchange rate information
struct ExchangeRates: Codable {
    let base: String
    let rates: [String: Double]
    let date: String?
    
    /// Get exchange rate between two currencies
    func getRate(from sourceCurrency: String, to targetCurrency: String) -> Double? {
        guard sourceCurrency != targetCurrency else { return 1.0 }
        guard let sourceRate = rates[sourceCurrency],
              let targetRate = rates[targetCurrency] else { return nil }
        return targetRate / sourceRate
    }
}

/// Represents a completed currency exchange transaction
struct ExchangeTransaction {
    let fromCurrency: String
    let toCurrency: String
    let fromAmount: Double
    let toAmount: Double
    let exchangeRate: Double
    let timestamp: Date
    
    var description: String {
        return "\(String(format: "%.2f", fromAmount)) \(fromCurrency) → \(String(format: "%.2f", toAmount)) \(toCurrency)"
    }
}
