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

/// A single exchange rate entry from the API
struct Rate: Codable {
    let currencyCode: String
    let value: Double
}

/// Represents exchange rate information fetched from the API
struct ExchangeRates: Codable {
    let base: String
    let rates: [Rate]
    let date: String?

    // Explicit memberwise init so tests can construct instances directly.
    init(base: String, rates: [Rate], date: String?) {
        self.base = base
        self.rates = rates
        self.date = date
    }

    // The API encodes rate values as JSON strings ("1.23"), not numbers,
    // so the default Codable synthesis would fail with a type mismatch.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        base = try container.decode(String.self, forKey: .base)
        date = try container.decodeIfPresent(String.self, forKey: .date)

        let rawRates = try container.decode([String: String].self, forKey: .rates)
        rates = rawRates.compactMap { code, valueString in
            guard let value = Double(valueString) else { return nil }
            return Rate(currencyCode: code, value: value)
        }
    }

    /// Get exchange rate between two currencies
    func getRate(from sourceCurrency: String, to targetCurrency: String) -> Double? {
        guard sourceCurrency != targetCurrency else { return 1.0 }
        guard let sourceRate = rates.first(where: { $0.currencyCode == sourceCurrency })?.value,
              let targetRate = rates.first(where: { $0.currencyCode == targetCurrency })?.value else { return nil }
        return targetRate / sourceRate
    }
}

/// Represents a completed currency exchange transaction
struct ExchangeTransaction: Codable {
    let fromCurrency: String
    let toCurrency: String
    let fromAmount: Double
    let toAmount: Double
    let exchangeRate: Double
    let timestamp: Date
    
    /// Commission amount deducted during transaction
    let commissionAmount: Double
    
    var description: String {
        return "\(String(format: "%.2f", fromAmount)) \(fromCurrency) → \(String(format: "%.2f", toAmount)) \(toCurrency)"
    }
}
