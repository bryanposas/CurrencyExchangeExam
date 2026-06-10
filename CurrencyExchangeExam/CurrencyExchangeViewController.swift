//
//  CurrencyExchangeViewController.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import UIKit

final class CurrencyExchangeViewController: UIViewController {

    private enum CurrencySlot { case sell, receive }

    // MARK: - UI: Navigation
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: - UI: Balances
    private let balancesSectionLabel = UILabel()
    private let balancesScrollView = UIScrollView()
    private let balancesStackView = UIStackView()

    // MARK: - UI: Exchange Rows
    private let exchangeSectionLabel = UILabel()

    private let sellIconView = CircleIconView(color: .systemRed, arrowUp: true)
    private let sellTitleLabel = UILabel()
    private let sellAmountLabel = UILabel()
    private let sellCurrencyButton = UIButton(type: .system)

    private let rowDivider = UIView()

    private let receiveIconView = CircleIconView(color: .systemGreen, arrowUp: false)
    private let receiveTitleLabel = UILabel()
    private let receiveAmountLabel = UILabel()
    private let receiveCurrencyButton = UIButton(type: .system)

    private let commissionInfoLabel = UILabel()

    // MARK: - UI: Submit
    private let submitButton = UIButton(type: .system)

    // MARK: - UI: Numpad
    private let numpadContainerView = UIView()

    // MARK: - Properties
    private let viewModel: CurrencyExchangeViewModel
    private let alertPresenter: AlertPresenting
    private var sellCurrency: String = Constants.Account.initialCurrency
    private var receiveCurrency: String = "EUR"
    private var activeCurrencySlot: CurrencySlot = .sell

    private var amountString: String = "0" {
        didSet { updateAmountDisplays() }
    }

    // MARK: - Init

    init(viewModel: CurrencyExchangeViewModel = CurrencyExchangeViewModel(),
         alertPresenter: AlertPresenting = AlertPresenter()) {
        self.viewModel = viewModel
        self.alertPresenter = alertPresenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        viewModel.setDelegate(self)
        viewModel.refreshExchangeRates()
        updateBalanceDisplay()
    }

    // MARK: - Navigation Bar

    private func setupNavigationBar() {
        title = "Currency Exchange"

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.37, green: 0.62, blue: 0.82, alpha: 1.0)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingIndicator)
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        setupBalancesSection()
        setupExchangeSection()
        setupSubmitButton()
        setupNumpad()
        setupConstraints()
    }

    private func setupBalancesSection() {
        balancesSectionLabel.text = "MY BALANCES"
        balancesSectionLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        balancesSectionLabel.textColor = .secondaryLabel

        balancesScrollView.showsHorizontalScrollIndicator = false

        balancesStackView.axis = .horizontal
        balancesStackView.spacing = 24
        balancesStackView.alignment = .center

        [balancesSectionLabel, balancesScrollView].forEach(addToView)
        balancesStackView.translatesAutoresizingMaskIntoConstraints = false
        balancesScrollView.addSubview(balancesStackView)
    }

    private func setupExchangeSection() {
        exchangeSectionLabel.text = "CURRENCY EXCHANGE"
        exchangeSectionLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        exchangeSectionLabel.textColor = .secondaryLabel

        sellTitleLabel.text = "Exchange"
        sellTitleLabel.font = .systemFont(ofSize: 17)

        sellAmountLabel.text = "0"
        sellAmountLabel.font = .systemFont(ofSize: 22)
        sellAmountLabel.textColor = .label
        sellAmountLabel.textAlignment = .right

        configureCurrencyButton(sellCurrencyButton, currency: sellCurrency)
        sellCurrencyButton.addTarget(self, action: #selector(sellCurrencyTapped), for: .touchUpInside)

        rowDivider.backgroundColor = .separator

        receiveTitleLabel.text = "Receive"
        receiveTitleLabel.font = .systemFont(ofSize: 17)

        receiveAmountLabel.text = "+0.00"
        receiveAmountLabel.font = .systemFont(ofSize: 22)
        receiveAmountLabel.textColor = .systemGreen
        receiveAmountLabel.textAlignment = .right

        configureCurrencyButton(receiveCurrencyButton, currency: receiveCurrency)
        receiveCurrencyButton.addTarget(self, action: #selector(receiveCurrencyTapped), for: .touchUpInside)

        let commissionPct = Int(Constants.Account.commissionRate * 100)
        commissionInfoLabel.text = "Commission: \(commissionPct)% per transaction"
        commissionInfoLabel.font = .systemFont(ofSize: 12)
        commissionInfoLabel.textColor = .secondaryLabel
        commissionInfoLabel.textAlignment = .center

        [exchangeSectionLabel,
         sellIconView, sellTitleLabel, sellAmountLabel, sellCurrencyButton,
         rowDivider,
         receiveIconView, receiveTitleLabel, receiveAmountLabel, receiveCurrencyButton,
         commissionInfoLabel].forEach(addToView)
    }

    private func setupSubmitButton() {
        submitButton.setTitle("Exchange", for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        submitButton.backgroundColor = UIColor(red: 0.37, green: 0.62, blue: 0.82, alpha: 0.85)
        submitButton.layer.cornerRadius = 25
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        addToView(submitButton)
    }

    private func setupNumpad() {
        numpadContainerView.backgroundColor = UIColor.systemGray5
        addToView(numpadContainerView)

        let keys: [[String]] = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            [".", "0", "⌫"]
        ]

        let letterMap: [String: String] = [
            "2": "ABC", "3": "DEF", "4": "GHI", "5": "JKL",
            "6": "MNO", "7": "PQRS", "8": "TUV", "9": "WXYZ"
        ]

        let outerStack = UIStackView()
        outerStack.axis = .vertical
        outerStack.distribution = .fillEqually
        outerStack.spacing = 1
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        numpadContainerView.addSubview(outerStack)

        for row in keys {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 1

            for key in row {
                let btn = UIButton(type: .system)
                btn.backgroundColor = .systemBackground
                btn.accessibilityIdentifier = key
                btn.addTarget(self, action: #selector(numpadKeyTapped(_:)), for: .touchUpInside)

                if let letters = letterMap[key] {
                    let numLabel = UILabel()
                    numLabel.text = key
                    numLabel.font = .systemFont(ofSize: 24, weight: .regular)
                    numLabel.textColor = .label
                    numLabel.textAlignment = .center

                    let letLabel = UILabel()
                    letLabel.text = letters
                    letLabel.font = .systemFont(ofSize: 10, weight: .regular)
                    letLabel.textColor = .label
                    letLabel.textAlignment = .center

                    let stack = UIStackView(arrangedSubviews: [numLabel, letLabel])
                    stack.axis = .vertical
                    stack.spacing = 2
                    stack.isUserInteractionEnabled = false
                    stack.translatesAutoresizingMaskIntoConstraints = false
                    btn.addSubview(stack)
                    NSLayoutConstraint.activate([
                        stack.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
                        stack.centerYAnchor.constraint(equalTo: btn.centerYAnchor)
                    ])
                } else {
                    btn.setTitle(key, for: .normal)
                    btn.setTitleColor(.label, for: .normal)
                    btn.titleLabel?.font = .systemFont(ofSize: 24, weight: .regular)
                }

                rowStack.addArrangedSubview(btn)
            }

            outerStack.addArrangedSubview(rowStack)
        }

        NSLayoutConstraint.activate([
            outerStack.topAnchor.constraint(equalTo: numpadContainerView.topAnchor, constant: 1),
            outerStack.leadingAnchor.constraint(equalTo: numpadContainerView.leadingAnchor, constant: 1),
            outerStack.trailingAnchor.constraint(equalTo: numpadContainerView.trailingAnchor, constant: -1),
            outerStack.bottomAnchor.constraint(equalTo: numpadContainerView.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupConstraints() {
        let pad: CGFloat = 16
        let safe = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            // MY BALANCES
            balancesSectionLabel.topAnchor.constraint(equalTo: safe.topAnchor, constant: 16),
            balancesSectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),

            balancesScrollView.topAnchor.constraint(equalTo: balancesSectionLabel.bottomAnchor, constant: 8),
            balancesScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            balancesScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            balancesScrollView.heightAnchor.constraint(equalToConstant: 40),

            balancesStackView.topAnchor.constraint(equalTo: balancesScrollView.topAnchor),
            balancesStackView.bottomAnchor.constraint(equalTo: balancesScrollView.bottomAnchor),
            balancesStackView.leadingAnchor.constraint(equalTo: balancesScrollView.leadingAnchor, constant: pad),
            balancesStackView.trailingAnchor.constraint(equalTo: balancesScrollView.trailingAnchor, constant: -pad),
            balancesStackView.heightAnchor.constraint(equalTo: balancesScrollView.heightAnchor),

            // CURRENCY EXCHANGE
            exchangeSectionLabel.topAnchor.constraint(equalTo: balancesScrollView.bottomAnchor, constant: 20),
            exchangeSectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),

            // Sell row
            sellIconView.topAnchor.constraint(equalTo: exchangeSectionLabel.bottomAnchor, constant: 16),
            sellIconView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            sellIconView.widthAnchor.constraint(equalToConstant: 40),
            sellIconView.heightAnchor.constraint(equalToConstant: 40),

            sellTitleLabel.centerYAnchor.constraint(equalTo: sellIconView.centerYAnchor),
            sellTitleLabel.leadingAnchor.constraint(equalTo: sellIconView.trailingAnchor, constant: 12),

            sellCurrencyButton.centerYAnchor.constraint(equalTo: sellIconView.centerYAnchor),
            sellCurrencyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),

            sellAmountLabel.centerYAnchor.constraint(equalTo: sellIconView.centerYAnchor),
            sellAmountLabel.trailingAnchor.constraint(equalTo: sellCurrencyButton.leadingAnchor, constant: -8),
            sellAmountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: sellTitleLabel.trailingAnchor, constant: 8),

            // Divider
            rowDivider.topAnchor.constraint(equalTo: sellIconView.bottomAnchor, constant: 14),
            rowDivider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            rowDivider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            rowDivider.heightAnchor.constraint(equalToConstant: 0.5),

            // Receive row
            receiveIconView.topAnchor.constraint(equalTo: rowDivider.bottomAnchor, constant: 14),
            receiveIconView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            receiveIconView.widthAnchor.constraint(equalToConstant: 40),
            receiveIconView.heightAnchor.constraint(equalToConstant: 40),

            receiveTitleLabel.centerYAnchor.constraint(equalTo: receiveIconView.centerYAnchor),
            receiveTitleLabel.leadingAnchor.constraint(equalTo: receiveIconView.trailingAnchor, constant: 12),

            receiveCurrencyButton.centerYAnchor.constraint(equalTo: receiveIconView.centerYAnchor),
            receiveCurrencyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),

            receiveAmountLabel.centerYAnchor.constraint(equalTo: receiveIconView.centerYAnchor),
            receiveAmountLabel.trailingAnchor.constraint(equalTo: receiveCurrencyButton.leadingAnchor, constant: -8),
            receiveAmountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: receiveTitleLabel.trailingAnchor, constant: 8),

            // Commission label
            commissionInfoLabel.topAnchor.constraint(equalTo: receiveIconView.bottomAnchor, constant: 10),
            commissionInfoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Submit button
            submitButton.topAnchor.constraint(equalTo: commissionInfoLabel.bottomAnchor, constant: 16),
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            submitButton.heightAnchor.constraint(equalToConstant: 50),

            // Numpad
            numpadContainerView.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: 16),
            numpadContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            numpadContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            numpadContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            numpadContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 240)
        ])
    }

    // MARK: - Helpers

    private func addToView(_ subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subview)
    }

    private func configureCurrencyButton(_ button: UIButton, currency: String) {
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)

        var title = currency
        if #available(iOS 13.0, *) {
            let chevron = UIImage(systemName: "chevron.down",
                                  withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .medium))
            button.setImage(chevron, for: .normal)
            button.tintColor = .label
            button.semanticContentAttribute = .forceRightToLeft
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
        } else {
            title += " ▾"
        }
        button.setTitle(title, for: .normal)
    }

    // MARK: - Amount Handling

    private func handleNumpadKey(_ key: String) {
        switch key {
        case "⌫":
            if amountString.count <= 1 {
                amountString = "0"
            } else {
                amountString.removeLast()
            }
        case ".":
            if !amountString.contains(".") {
                amountString += "."
            }
        default:
            if amountString == "0" {
                amountString = key
            } else if let dotIndex = amountString.firstIndex(of: "."),
                      amountString.distance(from: dotIndex, to: amountString.endIndex) > 2 {
                // Limit to 2 decimal places
                break
            } else {
                amountString += key
            }
        }
    }

    private func updateAmountDisplays() {
        sellAmountLabel.text = amountString

        guard let amount = Double(amountString), amount > 0 else {
            receiveAmountLabel.text = "+0.00"
            return
        }

        if let converted = viewModel.calculateExchangeAmount(amount: amount, from: sellCurrency, to: receiveCurrency) {
            receiveAmountLabel.text = String(format: "+%.2f", converted)
        } else {
            receiveAmountLabel.text = "+---"
        }
    }

    private func updateBalanceDisplay() {
        balancesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let balances = viewModel.getBalances()
        for (currency, balance) in balances.sorted(by: { $0.key < $1.key }) {
            let label = UILabel()
            label.text = String(format: "%.2f %@", balance, currency)
            label.font = .systemFont(ofSize: 18, weight: .bold)
            label.textColor = .label
            balancesStackView.addArrangedSubview(label)
        }
    }

    // MARK: - Actions

    @objc private func numpadKeyTapped(_ sender: UIButton) {
        handleNumpadKey(sender.accessibilityIdentifier ?? "")
    }

    @objc private func sellCurrencyTapped() {
        activeCurrencySlot = .sell
        presentCurrencyPicker()
    }

    @objc private func receiveCurrencyTapped() {
        activeCurrencySlot = .receive
        presentCurrencyPicker()
    }

    private func presentCurrencyPicker() {
        let currencies = viewModel.getAvailableCurrencies()
        let picker = CurrencyPickerViewController(currencies: currencies, delegate: self)
        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            nav.sheetPresentationController?.detents = [.medium()]
        }
        present(nav, animated: true)
    }

    @objc private func submitTapped() {
        guard let amount = Double(amountString), amount > 0 else {
            alertPresenter.showAlert(on: self, title: "Invalid Amount", message: "Please enter a valid amount.")
            return
        }

        let commission = amount * Constants.Account.commissionRate
        let convertedAmount = viewModel.calculateExchangeAmount(amount: amount, from: sellCurrency, to: receiveCurrency)
        let receiveText = convertedAmount.map { String(format: "%.2f %@", $0, receiveCurrency) } ?? "---"

        alertPresenter.showExchangeConfirmation(
            on: self,
            sellAmount: amount,
            sellCurrency: sellCurrency,
            receiveText: receiveText,
            commission: commission
        ) { [weak self] in
            guard let self else { return }
            self.viewModel.performExchange(amount: amount, from: self.sellCurrency, to: self.receiveCurrency)
        }
    }
}

// MARK: - CurrencyExchangeViewModelDelegate

extension CurrencyExchangeViewController: CurrencyExchangeViewModelDelegate {
    func viewModelDidUpdateBalances() {
        DispatchQueue.main.async {
            self.updateBalanceDisplay()
        }
    }

    func viewModelDidUpdateRates() {
        DispatchQueue.main.async {
            self.updateAmountDisplays()
        }
    }

    func viewModelDidCompleteExchange(_ transaction: ExchangeTransaction) {
        DispatchQueue.main.async {
            self.amountString = "0"
            self.updateBalanceDisplay()
            let msg = String(
                format: "You sold %.2f %@ and received %.2f %@.\nFee: %.2f %@",
                transaction.fromAmount, transaction.fromCurrency,
                transaction.toAmount, transaction.toCurrency,
                transaction.commissionAmount, transaction.fromCurrency
            )
            self.alertPresenter.showAlert(on: self, title: "Exchange Successful", message: msg)
        }
    }

    func viewModelDidEncounterError(_ error: AppError) {
        DispatchQueue.main.async {
            self.alertPresenter.showAlert(on: self, title: "Error", message: error.errorDescription ?? "An error occurred.")
        }
    }

    func viewModelIsLoadingRates(_ isLoading: Bool) {
        DispatchQueue.main.async {
            isLoading ? self.loadingIndicator.startAnimating() : self.loadingIndicator.stopAnimating()
        }
    }
}

// MARK: - CurrencyPickerDelegate

extension CurrencyExchangeViewController: CurrencyPickerDelegate {
    func currencyPickerDidSelect(_ currency: String) {
        switch activeCurrencySlot {
        case .sell:
            sellCurrency = currency
            configureCurrencyButton(sellCurrencyButton, currency: currency)
        case .receive:
            receiveCurrency = currency
            configureCurrencyButton(receiveCurrencyButton, currency: currency)
        }
        updateAmountDisplays()
    }
}

// MARK: - CircleIconView

private final class CircleIconView: UIView {
    init(color: UIColor, arrowUp: Bool) {
        super.init(frame: .zero)
        backgroundColor = color
        layer.cornerRadius = 20
        clipsToBounds = true

        let imageView = UIImageView()
        let symbolName = arrowUp ? "arrow.up" : "arrow.down"
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
            imageView.image = UIImage(systemName: symbolName, withConfiguration: config)
        }
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 18),
            imageView.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}
