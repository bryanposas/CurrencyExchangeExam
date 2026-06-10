//
//  ExchangeViewController.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//
//  Reusable modal for performing a currency exchange. The sell currency is fixed
//  to the one passed via `initialSellCurrency`; only the receive currency is selectable.
//  Wrap in UINavigationController before presenting as a pageSheet.

import UIKit

// MARK: - ExchangeViewController

final class ExchangeViewController: UIViewController {

    // MARK: - UI: Navigation

    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: - UI: Exchange Rows

    private let sellIconView = CircleIconView(color: .systemRed, arrowUp: true)
    private let sellTitleLabel = UILabel()
    private let sellAmountLabel = UILabel()
    private let sellCurrencyLabel = UILabel()

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

    /// Called after a successful exchange and the success alert is dismissed.
    /// Use this to refresh any presenting view controller that is not notified
    /// via viewWillAppear (e.g. pageSheet presenters).
    var onExchangeCompleted: (() -> Void)?

    private let viewModel: ExchangeViewModel
    private let alertPresenter: AlertPresenting
    private let sellCurrency: String
    private var receiveCurrency: String

    private var amountString: String = "0" {
        didSet { updateAmountDisplays() }
    }

    // MARK: - Init

    init(
        viewModel: ExchangeViewModel,
        initialSellCurrency: String = Constants.Account.initialCurrency,
        alertPresenter: AlertPresenting = AlertPresenter()
    ) {
        self.viewModel = viewModel
        self.sellCurrency = initialSellCurrency
        self.receiveCurrency = initialSellCurrency == "EUR" ? "USD" : "EUR"
        self.alertPresenter = alertPresenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupExchangeRows()
        setupSubmitButton()
        setupNumpad()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.delegate = self
        viewModel.refreshRatesIfNeeded()
        updateAmountDisplays()
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

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
    }

    // MARK: - UI Setup

    private func setupExchangeRows() {
        sellTitleLabel.text = Strings.sellTitle
        sellTitleLabel.font = .systemFont(ofSize: 17)

        sellAmountLabel.text = "0"
        sellAmountLabel.font = .systemFont(ofSize: 22)
        sellAmountLabel.textColor = .label
        sellAmountLabel.textAlignment = .right

        sellCurrencyLabel.text = sellCurrency
        sellCurrencyLabel.font = .systemFont(ofSize: 17, weight: .medium)
        sellCurrencyLabel.textColor = .label

        rowDivider.backgroundColor = .separator

        receiveTitleLabel.text = Strings.receiveTitle
        receiveTitleLabel.font = .systemFont(ofSize: 17)

        receiveAmountLabel.text = "+0.00"
        receiveAmountLabel.font = .systemFont(ofSize: 22)
        receiveAmountLabel.textColor = .systemGreen
        receiveAmountLabel.textAlignment = .right

        configureCurrencyButton(receiveCurrencyButton, currency: receiveCurrency)
        receiveCurrencyButton.addTarget(self, action: #selector(receiveCurrencyTapped), for: .touchUpInside)

        let commissionPct = Int(Constants.Account.commissionRate * 100)
        commissionInfoLabel.text = String(format: Strings.commissionFormat, commissionPct)
        commissionInfoLabel.font = .systemFont(ofSize: 12)
        commissionInfoLabel.textColor = .secondaryLabel
        commissionInfoLabel.textAlignment = .center

        [sellIconView, sellTitleLabel, sellAmountLabel, sellCurrencyLabel,
         rowDivider,
         receiveIconView, receiveTitleLabel, receiveAmountLabel, receiveCurrencyButton,
         commissionInfoLabel].forEach(addToView)
    }

    private func setupSubmitButton() {
        submitButton.setTitle(Strings.exchangeButtonTitle, for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        submitButton.backgroundColor = Colors.buttonBackground
        submitButton.layer.cornerRadius = Layout.buttonCornerRadius
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        addToView(submitButton)
    }

    private func setupNumpad() {
        numpadContainerView.backgroundColor = .systemGray5
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
        let pad = Layout.edgePadding

        NSLayoutConstraint.activate([
            // Sell row
            sellIconView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            sellIconView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            sellIconView.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            sellIconView.heightAnchor.constraint(equalToConstant: Layout.iconSize),

            sellTitleLabel.centerYAnchor.constraint(equalTo: sellIconView.centerYAnchor),
            sellTitleLabel.leadingAnchor.constraint(equalTo: sellIconView.trailingAnchor, constant: 12),

            sellCurrencyLabel.centerYAnchor.constraint(equalTo: sellIconView.centerYAnchor),
            sellCurrencyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),

            sellAmountLabel.centerYAnchor.constraint(equalTo: sellIconView.centerYAnchor),
            sellAmountLabel.trailingAnchor.constraint(equalTo: sellCurrencyLabel.leadingAnchor, constant: -8),
            sellAmountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: sellTitleLabel.trailingAnchor, constant: 8),

            // Divider
            rowDivider.topAnchor.constraint(equalTo: sellIconView.bottomAnchor, constant: 14),
            rowDivider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            rowDivider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            rowDivider.heightAnchor.constraint(equalToConstant: 0.5),

            // Receive row
            receiveIconView.topAnchor.constraint(equalTo: rowDivider.bottomAnchor, constant: 14),
            receiveIconView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            receiveIconView.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            receiveIconView.heightAnchor.constraint(equalToConstant: Layout.iconSize),

            receiveTitleLabel.centerYAnchor.constraint(equalTo: receiveIconView.centerYAnchor),
            receiveTitleLabel.leadingAnchor.constraint(equalTo: receiveIconView.trailingAnchor, constant: 12),

            receiveCurrencyButton.centerYAnchor.constraint(equalTo: receiveIconView.centerYAnchor),
            receiveCurrencyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),

            receiveAmountLabel.centerYAnchor.constraint(equalTo: receiveIconView.centerYAnchor),
            receiveAmountLabel.trailingAnchor.constraint(equalTo: receiveCurrencyButton.leadingAnchor, constant: -8),
            receiveAmountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: receiveTitleLabel.trailingAnchor, constant: 8),

            // Commission
            commissionInfoLabel.topAnchor.constraint(equalTo: receiveIconView.bottomAnchor, constant: 10),
            commissionInfoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Submit button
            submitButton.topAnchor.constraint(equalTo: commissionInfoLabel.bottomAnchor, constant: 16),
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            submitButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight),

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
        button.setTitle(currency, for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)

        let chevron = UIImage(
            systemName: "chevron.down",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        )
        button.setImage(chevron, for: .normal)
        button.tintColor = .label
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
    }

    // MARK: - Amount Handling

    private func handleNumpadKey(_ key: String) {
        switch key {
        case "⌫":
            amountString = amountString.count <= 1 ? "0" : String(amountString.dropLast())
        case ".":
            if !amountString.contains(".") { amountString += "." }
        default:
            if amountString == "0" {
                amountString = key
            } else if let dot = amountString.firstIndex(of: "."),
                      amountString.distance(from: dot, to: amountString.endIndex) > 2 {
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

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func numpadKeyTapped(_ sender: UIButton) {
        handleNumpadKey(sender.accessibilityIdentifier ?? "")
    }

    @objc private func receiveCurrencyTapped() {
        presentCurrencyPicker()
    }

    private func presentCurrencyPicker() {
        let picker = CurrencyPickerViewController(
            currencies: viewModel.getAvailableCurrencies(),
            delegate: self
        )
        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            nav.sheetPresentationController?.detents = [.medium()]
        }
        present(nav, animated: true)
    }

    @objc private func submitTapped() {
        guard let amount = Double(amountString), amount > 0 else {
            alertPresenter.showAlert(
                on: self,
                title: Strings.invalidAmountTitle,
                message: Strings.invalidAmountMessage
            )
            return
        }

        let commission = amount * Constants.Account.commissionRate
        let converted = viewModel.calculateExchangeAmount(amount: amount, from: sellCurrency, to: receiveCurrency)
        let receiveText = converted.map { String(format: "%.2f %@", $0, receiveCurrency) } ?? "---"

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

// MARK: - ExchangeViewModelDelegate

extension ExchangeViewController: ExchangeViewModelDelegate {
    func exchangeViewModelDidUpdateRates() {
        DispatchQueue.main.async { self.updateAmountDisplays() }
    }

    func exchangeViewModelDidCompleteExchange(_ transaction: ExchangeTransaction) {
        DispatchQueue.main.async {
            self.amountString = "0"
            let msg = String(
                format: Strings.successMessageFormat,
                transaction.fromAmount, transaction.fromCurrency,
                transaction.toAmount, transaction.toCurrency,
                transaction.commissionAmount, transaction.fromCurrency
            )
            let alert = UIAlertController(
                title: Strings.successTitle,
                message: msg,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: Strings.okButton, style: .default) { [weak self] _ in
                guard let self else { return }
                self.onExchangeCompleted?()
                self.dismiss(animated: true)
            })
            self.present(alert, animated: true)
        }
    }

    func exchangeViewModelDidEncounterError(_ error: AppError) {
        DispatchQueue.main.async {
            self.alertPresenter.showAlert(
                on: self,
                title: Strings.errorTitle,
                message: error.errorDescription ?? Strings.errorGeneric
            )
        }
    }

    func exchangeViewModelIsLoadingRates(_ isLoading: Bool) {
        DispatchQueue.main.async {
            isLoading
                ? self.loadingIndicator.startAnimating()
                : self.loadingIndicator.stopAnimating()
        }
    }
}

// MARK: - CurrencyPickerDelegate

extension ExchangeViewController: CurrencyPickerDelegate {
    func currencyPickerDidSelect(_ currency: String) {
        receiveCurrency = currency
        configureCurrencyButton(receiveCurrencyButton, currency: currency)
        updateAmountDisplays()
    }
}

// MARK: - Constants

private enum Strings {
    static let navTitle = "Currency Exchange"
    static let sellTitle = "Exchange"
    static let receiveTitle = "Receive"
    static let exchangeButtonTitle = "Exchange"
    static let commissionFormat = "Commission: %d%% per transaction"
    static let invalidAmountTitle = "Invalid Amount"
    static let invalidAmountMessage = "Please enter a valid amount."
    static let successTitle = "Exchange Successful"
    static let successMessageFormat = "You sold %.2f %@ and received %.2f %@.\nFee: %.2f %@"
    static let okButton = "OK"
    static let errorTitle = "Error"
    static let errorGeneric = "An error occurred."
}

private enum Colors {
    static let navBarBackground = UIColor(red: 0.37, green: 0.62, blue: 0.82, alpha: 1.0)
    static let buttonBackground = UIColor(red: 0.37, green: 0.62, blue: 0.82, alpha: 0.85)
}

private enum Layout {
    static let edgePadding: CGFloat = 16
    static let iconSize: CGFloat = 40
    static let buttonHeight: CGFloat = 50
    static let buttonCornerRadius: CGFloat = 25
}

// MARK: - CircleIconView

private final class CircleIconView: UIView {

    init(color: UIColor, arrowUp: Bool) {
        super.init(frame: .zero)
        backgroundColor = color
        layer.cornerRadius = 20
        clipsToBounds = true

        let symbolName = arrowUp ? "arrow.up" : "arrow.down"
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        let imageView = UIImageView(image: UIImage(systemName: symbolName, withConfiguration: config))
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

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }
}
