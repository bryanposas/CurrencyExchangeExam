//
//  CurrencyExchangeViewModel.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import Foundation

/// Protocol for view model observers to react to state changes
protocol CurrencyExchangeViewModelDelegate: AnyObject {
    func viewModelDidUpdateBalances()
    func viewModelDidUpdateRates()
    func viewModelDidCompleteExchange(_ transaction: ExchangeTransaction)
    func viewModelDidEncounterError(_ error: AppError)
    func viewModelIsLoadingRates(_ isLoading: Bool)
}

/// ViewModel for the currency exchange feature
/// Manages the communication between the view and business logic
final class CurrencyExchangeViewModel {
    // MARK: - Properties
    private let exchangeManager: CurrencyExchangeManager
    private weak var delegate: CurrencyExchangeViewModelDelegate?
    
    private(set) var isLoadingRates = false {
        didSet {
            delegate?.viewModelIsLoadingRates(isLoadingRates)
        }
    }
    
    // MARK: - Initialization
    init(exchangeManager: CurrencyExchangeManager = CurrencyExchangeManager(), delegate: CurrencyExchangeViewModelDelegate? = nil) {
        self.exchangeManager = exchangeManager
        self.delegate = delegate
    }
    
    // MARK: - Public Methods
    
    /// Set the view model delegate
    func setDelegate(_ delegate: CurrencyExchangeViewModelDelegate) {
        self.delegate = delegate
    }
    
    /// Get all available currencies
    func getAvailableCurrencies() -> [String] {
        return exchangeManager.getAllAvailableCurrencies()
    }
    
    /// Get current balances
    func getBalances() -> [String: Double] {
        return exchangeManager.getBalances()
    }
    
    /// Get balance for a specific currency
    func getBalance(for currencyCode: String) -> Double {
        return exchangeManager.getBalance(for: currencyCode)
    }
    
    /// Get the exchange rate between two currencies
    func getExchangeRate(from sourceCurrency: String, to targetCurrency: String) -> Double? {
        guard let rates = exchangeManager.getExchangeRates() else { return nil }
        return rates.getRate(from: sourceCurrency, to: targetCurrency)
    }
    
    /// Calculate the amount in target currency
    func calculateExchangeAmount(amount: Double, from sourceCurrency: String, to targetCurrency: String) -> Double? {
        guard let rate = getExchangeRate(from: sourceCurrency, to: targetCurrency) else { return nil }
        return amount * rate
    }
    
    /// Perform currency exchange
    /// - Parameters:
    ///   - amount: Amount to exchange
    ///   - fromCurrency: Source currency
    ///   - toCurrency: Target currency
    func performExchange(amount: Double, from fromCurrency: String, to toCurrency: String) {
        let result = exchangeManager.exchange(amount: amount, from: fromCurrency, to: toCurrency)
        
        switch result {
        case .success(let transaction):
            delegate?.viewModelDidCompleteExchange(transaction)
            delegate?.viewModelDidUpdateBalances()
        case .failure(let error):
            delegate?.viewModelDidEncounterError(error)
        }
    }
    
    /// Refresh exchange rates from the network
    func refreshExchangeRates() {
        isLoadingRates = true
        
        exchangeManager.updateExchangeRates { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingRates = false
                
                switch result {
                case .success:
                    self?.delegate?.viewModelDidUpdateRates()
                case .failure(let error):
                    self?.delegate?.viewModelDidEncounterError(error)
                }
            }
        }
    }
    
    /// Get transaction history
    func getTransactionHistory() -> [ExchangeTransaction] {
        return exchangeManager.getTransactionHistory()
    }
    
    /// Check if exchange rates need refreshing
    func shouldRefreshRates() -> Bool {
        return exchangeManager.rateService.shouldRefreshRates()
    }
}
