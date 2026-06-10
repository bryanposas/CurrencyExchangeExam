//
//  BalanceDetailViewModel.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import Foundation

// MARK: - BalanceDetailViewModel

/// ViewModel for BalanceDetailViewController.
/// Provides read-only access to balance and transaction data for a specific currency,
/// and exposes a factory for the exchange modal ViewModel.
final class BalanceDetailViewModel {

    // MARK: - Properties

    private let manager: CurrencyExchangeManager

    // MARK: - Initialization

    init(manager: CurrencyExchangeManager) {
        self.manager = manager
    }

    // MARK: - Public Methods

    func getBalance(for currency: String) -> Double {
        manager.getBalance(for: currency)
    }

    /// Returns all transactions involving the given currency, newest first.
    func getTransactions(for currency: String) -> [ExchangeTransaction] {
        manager.getTransactionHistory().filter {
            $0.fromCurrency == currency || $0.toCurrency == currency
        }
    }

    // MARK: - Factory

    /// Creates the ViewModel for the exchange modal, sharing the same manager.
    func makeExchangeViewModel() -> ExchangeViewModel {
        ExchangeViewModel(manager: manager)
    }
}
