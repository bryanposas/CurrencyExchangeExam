//
//  BalancesViewModel.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import Foundation

// MARK: - Delegate

protocol BalancesViewModelDelegate: AnyObject {
    func balancesViewModelDidFinishRefreshing()
    func balancesViewModelIsLoadingRates(_ isLoading: Bool)
    func balancesViewModelDidEncounterError(_ error: AppError)
}

// MARK: - BalancesViewModel

/// ViewModel for BalancesViewController.
/// Owns rate refresh and exposes a factory for the detail-screen ViewModel.
final class BalancesViewModel {

    // MARK: - Properties

    private let manager: CurrencyExchangeManager
    weak var delegate: BalancesViewModelDelegate?

    // MARK: - Initialization

    init(manager: CurrencyExchangeManager) {
        self.manager = manager
    }

    // MARK: - Public Methods

    func getBalances() -> [String: Double] {
        manager.getBalances()
    }

    func refreshExchangeRates() {
        delegate?.balancesViewModelIsLoadingRates(true)
        manager.updateExchangeRates { [weak self] result in
            DispatchQueue.main.async {
                self?.delegate?.balancesViewModelIsLoadingRates(false)
                switch result {
                case .success:
                    self?.delegate?.balancesViewModelDidFinishRefreshing()
                case .failure(let error):
                    self?.delegate?.balancesViewModelDidEncounterError(error)
                }
            }
        }
    }

    // MARK: - Factory

    /// Creates the ViewModel for the balance detail screen, sharing the same manager.
    func makeDetailViewModel() -> BalanceDetailViewModel {
        BalanceDetailViewModel(manager: manager)
    }
}
