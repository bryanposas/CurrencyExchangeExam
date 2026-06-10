//
//  CurrencyExchangeManager.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import Foundation

/// Manages currency exchange operations and account balances
final class CurrencyExchangeManager {
    // MARK: - Properties
    private var account: Account
    private var exchangeRates: ExchangeRates?
    private(set) var transactionHistory: [ExchangeTransaction] = []
    
    let rateService: ExchangeRateService
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    init(rateService: ExchangeRateService = ExchangeRateService()) {
        self.rateService = rateService
        self.account = Account()
        // Initialize with 1000 EUR
        self.account.setBalance(1000, for: "EUR")
        self.setupAutoRefresh()
    }
    
    // MARK: - Public Methods
    
    /// Get the current account balances
    func getBalances() -> [String: Double] {
        return account.balances
    }
    
    /// Get balance for a specific currency
    func getBalance(for currencyCode: String) -> Double {
        return account.getBalance(for: currencyCode)
    }
    
    /// Get available currencies (those with balances > 0)
    func getAvailableCurrencies() -> [String] {
        return account.balances.keys.sorted()
    }
    
    /// Get all currencies that have exchange rates
    func getAllAvailableCurrencies() -> [String] {
        guard let rates = exchangeRates else { return getAvailableCurrencies() }
        return rates.rates.keys.sorted()
    }
    
    /// Perform a currency exchange
    /// - Parameters:
    ///   - amount: Amount to exchange
    ///   - fromCurrency: Source currency code
    ///   - toCurrency: Target currency code
    /// - Returns: Result with transaction details or error
    func exchange(amount: Double, from fromCurrency: String, to toCurrency: String) -> Result<ExchangeTransaction, AppError> {
        // Validation
        guard amount > 0 else { return .failure(.invalidAmount) }
        guard fromCurrency != toCurrency else { return .failure(.sameCurrency) }
        guard account.canExchange(amount: amount, from: fromCurrency) else { return .failure(.insufficientFunds) }
        
        // Get exchange rate
        guard let rates = exchangeRates else { return .failure(.invalidExchangeRate) }
        guard let rate = rates.getRate(from: fromCurrency, to: toCurrency) else {
            return .failure(.invalidExchangeRate)
        }
        
        // Calculate target amount
        let targetAmount = amount * rate
        
        // Update balances
        var updatedBalance = account.getBalance(for: fromCurrency) - amount
        account.setBalance(updatedBalance, for: fromCurrency)
        
        updatedBalance = account.getBalance(for: toCurrency) + targetAmount
        account.setBalance(updatedBalance, for: toCurrency)
        
        // Create transaction record
        let transaction = ExchangeTransaction(
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            fromAmount: amount,
            toAmount: targetAmount,
            exchangeRate: rate,
            timestamp: Date()
        )
        
        transactionHistory.append(transaction)
        return .success(transaction)
    }
    
    /// Update exchange rates
    /// - Parameter completion: Closure called when rates are updated
    func updateExchangeRates(completion: @escaping (Result<ExchangeRates, AppError>) -> Void) {
        rateService.fetchExchangeRates { [weak self] result in
            switch result {
            case .success(let rates):
                self?.exchangeRates = rates
                // Ensure all currencies with balances are represented in rates
                self?.ensureBaseCurrenciesExist(rates)
                completion(.success(rates))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get current exchange rates
    func getExchangeRates() -> ExchangeRates? {
        return exchangeRates
    }
    
    /// Get transaction history
    func getTransactionHistory() -> [ExchangeTransaction] {
        return transactionHistory.sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Private Methods
    
    /// Setup automatic refresh of exchange rates every 5 minutes
    private func setupAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.updateExchangeRates { _ in }
        }
    }
    
    /// Ensure base currencies exist in the rates (EUR should be present)
    private func ensureBaseCurrenciesExist(_ rates: ExchangeRates) {
        // If EUR is in our balances but not in rates, try to add it
        for currencyCode in account.balances.keys {
            if !rates.rates.keys.contains(currencyCode) && currencyCode == "EUR" {
                // Would need to adjust rates if EUR is not the base
            }
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
}
