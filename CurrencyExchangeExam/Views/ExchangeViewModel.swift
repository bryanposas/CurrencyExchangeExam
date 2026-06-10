//
//  ExchangeViewModel.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import Foundation

// MARK: - Delegate

protocol ExchangeViewModelDelegate: AnyObject {
    func exchangeViewModelDidCompleteExchange(_ transaction: ExchangeTransaction)
    func exchangeViewModelDidUpdateRates()
    func exchangeViewModelDidEncounterError(_ error: AppError)
    func exchangeViewModelIsLoadingRates(_ isLoading: Bool)
}

// MARK: - ExchangeViewModel

/// ViewModel for ExchangeViewController.
/// Handles exchange execution, amount calculation, and rate refresh for the modal screen.
final class ExchangeViewModel {

    // MARK: - Properties

    private let manager: CurrencyExchangeManager
    weak var delegate: ExchangeViewModelDelegate?

    // MARK: - Initialization

    init(manager: CurrencyExchangeManager) {
        self.manager = manager
    }

    // MARK: - Public Methods

    func getAvailableCurrencies() -> [String] {
        manager.getAllAvailableCurrencies()
    }

    func calculateExchangeAmount(amount: Double, from sourceCurrency: String, to targetCurrency: String) -> Double? {
        guard let rates = manager.getExchangeRates(),
              let rate = rates.getRate(from: sourceCurrency, to: targetCurrency) else { return nil }
        return amount * rate
    }

    func performExchange(amount: Double, from fromCurrency: String, to toCurrency: String) {
        switch manager.exchange(amount: amount, from: fromCurrency, to: toCurrency) {
        case .success(let transaction):
            delegate?.exchangeViewModelDidCompleteExchange(transaction)
        case .failure(let error):
            delegate?.exchangeViewModelDidEncounterError(error)
        }
    }

    func getBalance(for currency: String) -> Double {
        manager.getBalance(for: currency)
    }

    /// Returns the maximum sell amount such that sell + 1% commission ≤ available balance.
    func maximumSellAmount(for currency: String) -> Double {
        manager.getBalance(for: currency) / (1 + Constants.Account.commissionRate)
    }

    /// Triggers a rate fetch only if the cached rates have expired.
    func refreshRatesIfNeeded() {
        guard manager.rateService.shouldRefreshRates() else { return }
        delegate?.exchangeViewModelIsLoadingRates(true)
        manager.updateExchangeRates { [weak self] result in
            DispatchQueue.main.async {
                self?.delegate?.exchangeViewModelIsLoadingRates(false)
                switch result {
                case .success:
                    self?.delegate?.exchangeViewModelDidUpdateRates()
                case .failure(let error):
                    self?.delegate?.exchangeViewModelDidEncounterError(error)
                }
            }
        }
    }
}
