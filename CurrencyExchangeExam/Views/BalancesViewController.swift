//
//  CurrencyExchangeViewController.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//
//  This file contains BalancesViewController — the root screen that displays
//  each currency balance as a tappable card. Tapping a card navigates to
//  BalanceDetailViewController, which provides the exchange entry point.
//
//  Architectural note: the shared CurrencyExchangeViewModel is injected here
//  and passed down through the navigation stack so every screen operates on
//  the same account state without any singleton or shared-state coupling.

import UIKit

// MARK: - BalancesViewController

/// Root screen displaying all currency balances as scrollable cards.
/// Refreshes cards on `viewWillAppear` to reflect changes made on child screens.
final class BalancesViewController: UIViewController {

    // MARK: - UI

    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    // MARK: - Properties

    private let viewModel: BalancesViewModel
    private let alertPresenter: AlertPresenting
    private let networkMonitor: NetworkMonitoring

    // MARK: - Init

    init(
        viewModel: BalancesViewModel,
        networkMonitor: NetworkMonitoring = NetworkMonitor(),
        alertPresenter: AlertPresenting = AlertPresenter()
    ) {
        self.viewModel = viewModel
        self.networkMonitor = networkMonitor
        self.alertPresenter = alertPresenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupScrollLayout()
        viewModel.delegate = self
        viewModel.refreshExchangeRates()
        refreshBalanceCards()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reclaim delegate ownership whenever this screen becomes active.
        // Child screens (ExchangeViewController) temporarily take over the
        // delegate while they are visible; returning here restores it.
        viewModel.delegate = self
        refreshBalanceCards()
    }

    // MARK: - Navigation Bar

    private func setupNavigationBar() {
        title = Strings.Balances.navTitle

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Colors.navBarBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingIndicator)
    }

    // MARK: - Layout

    private func setupScrollLayout() {
        view.backgroundColor = .systemGroupedBackground

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        stackView.axis = .vertical
        stackView.spacing = Layout.cardSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        let p = Layout.padding
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: p),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: p),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -p),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -p),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -p * 2)
        ])
    }

    // MARK: - Data

    private func refreshBalanceCards() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let balances = viewModel.getBalances()
        for (currency, balance) in balances.sorted(by: { $0.key < $1.key }) {
            let card = BalanceCardView(currency: currency, balance: balance)
            card.onTap = { [weak self] in
                self?.navigateToDetail(currency: currency)
            }
            stackView.addArrangedSubview(card)
        }
    }

    // MARK: - Navigation

    private func navigateToDetail(currency: String) {
        let detailVM = viewModel.makeDetailViewModel()
        let detailVC = BalanceDetailViewController(currency: currency, viewModel: detailVM, networkMonitor: networkMonitor)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - CurrencyExchangeViewModelDelegate

extension BalancesViewController: BalancesViewModelDelegate {
    func balancesViewModelDidFinishRefreshing() {
        DispatchQueue.main.async { self.refreshBalanceCards() }
    }

    func balancesViewModelIsLoadingRates(_ isLoading: Bool) {
        DispatchQueue.main.async {
            isLoading
                ? self.loadingIndicator.startAnimating()
                : self.loadingIndicator.stopAnimating()
        }
    }

    func balancesViewModelDidEncounterError(_ error: AppError) {
        DispatchQueue.main.async {
            self.alertPresenter.showAlert(
                on: self,
                title: Strings.Error.title,
                message: error.errorDescription ?? Strings.Error.generic
            )
        }
    }
}

// MARK: - Constants

private enum Strings {
    enum Balances {
        static let navTitle = "My Balances"
    }
    enum Error {
        static let title = "Error"
        static let generic = "An error occurred."
    }
}

private enum Colors {
    static let navBarBackground = UIColor(red: 0.37, green: 0.62, blue: 0.82, alpha: 1.0)
}

private enum Layout {
    static let padding: CGFloat = 16
    static let cardSpacing: CGFloat = 16
}
