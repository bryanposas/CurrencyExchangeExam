//
//  BalancesViewController.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//
//  Root screen displaying each currency balance as a tappable card.
//  Owns a BalancesViewModel; navigates to BalanceDetailViewController on card tap.

import UIKit

// MARK: - BalancesViewController

final class BalancesViewController: UIViewController {

    // MARK: - UI

    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    // MARK: - Properties

    private let viewModel: BalancesViewModel
    private let alertPresenter: AlertPresenting

    // MARK: - Init

    init(
        viewModel: BalancesViewModel,
        alertPresenter: AlertPresenting = AlertPresenter()
    ) {
        self.viewModel = viewModel
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
        refreshBalanceCards()
    }

    // MARK: - Navigation Bar

    private func setupNavigationBar() {
        title = Strings.navTitle

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
        let detailVC = BalanceDetailViewController(
            currency: currency,
            viewModel: viewModel.makeDetailViewModel()
        )
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - BalancesViewModelDelegate

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
                title: Strings.errorTitle,
                message: error.errorDescription ?? Strings.errorGeneric
            )
        }
    }
}

// MARK: - Constants

private enum Strings {
    static let navTitle = "My Balances"
    static let errorTitle = "Error"
    static let errorGeneric = "An error occurred."
}

private enum Colors {
    static let navBarBackground = UIColor(red: 0.37, green: 0.62, blue: 0.82, alpha: 1.0)
}

private enum Layout {
    static let padding: CGFloat = 16
    static let cardSpacing: CGFloat = 16
}
