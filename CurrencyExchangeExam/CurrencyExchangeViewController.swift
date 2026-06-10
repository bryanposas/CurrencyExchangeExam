//
//  ContentView.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import UIKit

/// Main view controller for currency exchange functionality
final class CurrencyExchangeViewController: UIViewController {
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleLabel = UILabel()
    private let refreshButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    private let balancesStackView = UIStackView()
    private let balanceCards: NSMutableDictionary = NSMutableDictionary()
    
    private let exchangeContainerView = UIView()
    private let amountTextField = UITextField()
    private let fromCurrencyButton = UIButton(type: .system)
    private let toCurrencyButton = UIButton(type: .system)
    private let exchangeRateLabel = UILabel()
    private let resultLabel = UILabel()
    private let exchangeButton = UIButton(type: .system)
    
    private let historyLabel = UILabel()
    private let historyTableView = UITableView(frame: .zero, style: .plain)
    
    // MARK: - Properties
    private let viewModel: CurrencyExchangeViewModel
    private var selectedFromCurrency: String = "EUR"
    private var selectedToCurrency: String = "USD"
    
    // MARK: - Initialization
    init(viewModel: CurrencyExchangeViewModel = CurrencyExchangeViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.setDelegate(self)
        loadInitialData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if viewModel.shouldRefreshRates() {
            viewModel.refreshExchangeRates()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "Currency Exchange"
        
        // Refresh button
        refreshButton.setTitle("Refresh", for: .normal)
        refreshButton.addTarget(self, action: #selector(refreshButtonTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: refreshButton)
        
        // Loading indicator
        loadingIndicator.hidesWhenStopped = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: loadingIndicator)
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Title
        titleLabel.text = "Your Account"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Balances stack view
        balancesStackView.axis = .vertical
        balancesStackView.spacing = 12
        balancesStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(balancesStackView)
        
        // Exchange container
        exchangeContainerView.translatesAutoresizingMaskIntoConstraints = false
        exchangeContainerView.layer.borderColor = UIColor.systemGray4.cgColor
        exchangeContainerView.layer.borderWidth = 1
        exchangeContainerView.layer.cornerRadius = 8
        contentView.addSubview(exchangeContainerView)
        
        setupExchangeUI()
        
        // History
        historyLabel.text = "Transaction History"
        historyLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        historyLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(historyLabel)
        
        historyTableView.delegate = self
        historyTableView.dataSource = self
        historyTableView.register(UITableViewCell.self, forCellReuseIdentifier: "HistoryCell")
        historyTableView.isScrollEnabled = false
        historyTableView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(historyTableView)
        
        // Constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            balancesStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            balancesStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            balancesStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            exchangeContainerView.topAnchor.constraint(equalTo: balancesStackView.bottomAnchor, constant: 24),
            exchangeContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            exchangeContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            historyLabel.topAnchor.constraint(equalTo: exchangeContainerView.bottomAnchor, constant: 24),
            historyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            historyTableView.topAnchor.constraint(equalTo: historyLabel.bottomAnchor, constant: 12),
            historyTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            historyTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            historyTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            historyTableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
    }
    
    private func setupExchangeUI() {
        let padding: CGFloat = 16
        
        // Amount input
        amountTextField.placeholder = "Enter amount"
        amountTextField.font = UIFont.systemFont(ofSize: 16)
        amountTextField.keyboardType = .decimalPad
        amountTextField.borderStyle = .roundedRect
        amountTextField.translatesAutoresizingMaskIntoConstraints = false
        exchangeContainerView.addSubview(amountTextField)
        
        // From currency button
        fromCurrencyButton.setTitle("From: EUR", for: .normal)
        fromCurrencyButton.addTarget(self, action: #selector(fromCurrencyButtonTapped), for: .touchUpInside)
        fromCurrencyButton.translatesAutoresizingMaskIntoConstraints = false
        exchangeContainerView.addSubview(fromCurrencyButton)
        
        // To currency button
        toCurrencyButton.setTitle("To: USD", for: .normal)
        toCurrencyButton.addTarget(self, action: #selector(toCurrencyButtonTapped), for: .touchUpInside)
        toCurrencyButton.translatesAutoresizingMaskIntoConstraints = false
        exchangeContainerView.addSubview(toCurrencyButton)
        
        // Exchange rate label
        exchangeRateLabel.text = "Rate: calculating..."
        exchangeRateLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        exchangeRateLabel.textColor = .systemGray
        exchangeRateLabel.translatesAutoresizingMaskIntoConstraints = false
        exchangeContainerView.addSubview(exchangeRateLabel)
        
        // Result label
        resultLabel.text = "Result: ---"
        resultLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        exchangeContainerView.addSubview(resultLabel)
        
        // Exchange button
        exchangeButton.setTitle("Exchange", for: .normal)
        exchangeButton.setTitleColor(.white, for: .normal)
        exchangeButton.backgroundColor = .systemBlue
        exchangeButton.layer.cornerRadius = 8
        exchangeButton.addTarget(self, action: #selector(exchangeButtonTapped), for: .touchUpInside)
        exchangeButton.translatesAutoresizingMaskIntoConstraints = false
        exchangeContainerView.addSubview(exchangeButton)
        
        amountTextField.addTarget(self, action: #selector(amountTextDidChange), for: .editingChanged)
        
        // Layout
        NSLayoutConstraint.activate([
            amountTextField.topAnchor.constraint(equalTo: exchangeContainerView.topAnchor, constant: padding),
            amountTextField.leadingAnchor.constraint(equalTo: exchangeContainerView.leadingAnchor, constant: padding),
            amountTextField.trailingAnchor.constraint(equalTo: exchangeContainerView.trailingAnchor, constant: -padding),
            amountTextField.heightAnchor.constraint(equalToConstant: 44),
            
            fromCurrencyButton.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 12),
            fromCurrencyButton.leadingAnchor.constraint(equalTo: exchangeContainerView.leadingAnchor, constant: padding),
            fromCurrencyButton.widthAnchor.constraint(equalTo: exchangeContainerView.widthAnchor, multiplier: 0.5, constant: -padding/2),
            
            toCurrencyButton.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 12),
            toCurrencyButton.trailingAnchor.constraint(equalTo: exchangeContainerView.trailingAnchor, constant: -padding),
            toCurrencyButton.widthAnchor.constraint(equalTo: fromCurrencyButton.widthAnchor),
            
            exchangeRateLabel.topAnchor.constraint(equalTo: fromCurrencyButton.bottomAnchor, constant: 8),
            exchangeRateLabel.leadingAnchor.constraint(equalTo: exchangeContainerView.leadingAnchor, constant: padding),
            
            resultLabel.topAnchor.constraint(equalTo: exchangeRateLabel.bottomAnchor, constant: 12),
            resultLabel.leadingAnchor.constraint(equalTo: exchangeContainerView.leadingAnchor, constant: padding),
            
            exchangeButton.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 16),
            exchangeButton.leadingAnchor.constraint(equalTo: exchangeContainerView.leadingAnchor, constant: padding),
            exchangeButton.trailingAnchor.constraint(equalTo: exchangeContainerView.trailingAnchor, constant: -padding),
            exchangeButton.bottomAnchor.constraint(equalTo: exchangeContainerView.bottomAnchor, constant: -padding),
            exchangeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func loadInitialData() {
        viewModel.refreshExchangeRates()
    }
    
    private func updateBalanceDisplay() {
        // Clear existing cards
        balanceCards.removeAllObjects()
        balancesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add cards for each currency
        let balances = viewModel.getBalances()
        for (currency, balance) in balances.sorted(by: { $0.key < $1.key }) {
            let card = BalanceCardView(currency: currency, balance: balance)
            card.translatesAutoresizingMaskIntoConstraints = false
            card.heightAnchor.constraint(equalToConstant: 100).isActive = true
            balancesStackView.addArrangedSubview(card)
            balanceCards.setObject(card, forKey: currency as NSString)
        }
    }
    
    private func updateExchangeRateDisplay() {
        guard let amountText = amountTextField.text, let amount = Double(amountText), amount > 0 else {
            exchangeRateLabel.text = "Rate: ---"
            resultLabel.text = "Result: ---"
            return
        }
        
        if let rate = viewModel.getExchangeRate(from: selectedFromCurrency, to: selectedToCurrency) {
            exchangeRateLabel.text = String(format: "Rate: 1 %@ = %.4f %@", selectedFromCurrency, rate, selectedToCurrency)
            
            if let result = viewModel.calculateExchangeAmount(amount: amount, from: selectedFromCurrency, to: selectedToCurrency) {
                resultLabel.text = String(format: "Result: %.2f %@", result, selectedToCurrency)
            }
        } else {
            exchangeRateLabel.text = "Rate: ---"
            resultLabel.text = "Result: ---"
        }
    }
    
    // MARK: - Actions
    
    @objc private func refreshButtonTapped() {
        viewModel.refreshExchangeRates()
    }
    
    @objc private func fromCurrencyButtonTapped() {
        let picker = CurrencyPickerViewController(currencies: viewModel.getAvailableCurrencies(), delegate: self)
        let nav = UINavigationController(rootViewController: picker)
        nav.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = nav.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
            }
        }
        present(nav, animated: true)
    }
    
    @objc private func toCurrencyButtonTapped() {
        let picker = CurrencyPickerViewController(currencies: viewModel.getAvailableCurrencies(), delegate: self)
        picker.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = picker.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
            }
        }
        present(picker, animated: true)
    }
    
    @objc private func exchangeButtonTapped() {
        guard let amountText = amountTextField.text, let amount = Double(amountText) else {
            showAlert(title: "Invalid Amount", message: "Please enter a valid amount")
            return
        }
        
        viewModel.performExchange(amount: amount, from: selectedFromCurrency, to: selectedToCurrency)
    }
    
    @objc private func amountTextDidChange() {
        updateExchangeRateDisplay()
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - CurrencyExchangeViewModelDelegate
extension CurrencyExchangeViewController: CurrencyExchangeViewModelDelegate {
    func viewModelDidUpdateBalances() {
        DispatchQueue.main.async {
            self.updateBalanceDisplay()
            self.historyTableView.reloadData()
        }
    }
    
    func viewModelDidUpdateRates() {
        DispatchQueue.main.async {
            self.updateExchangeRateDisplay()
        }
    }
    
    func viewModelDidCompleteExchange(_ transaction: ExchangeTransaction) {
        DispatchQueue.main.async {
            self.amountTextField.text = ""
            self.updateExchangeRateDisplay()
            self.showAlert(title: "Exchange Successful", message: transaction.description)
        }
    }
    
    func viewModelDidEncounterError(_ error: AppError) {
        DispatchQueue.main.async {
            self.showAlert(title: "Error", message: error.errorDescription ?? "An error occurred")
        }
    }
    
    func viewModelIsLoadingRates(_ isLoading: Bool) {
        DispatchQueue.main.async {
            if isLoading {
                self.loadingIndicator.startAnimating()
            } else {
                self.loadingIndicator.stopAnimating()
            }
        }
    }
}

// MARK: - CurrencyPickerDelegate
extension CurrencyExchangeViewController: CurrencyPickerDelegate {
    func currencyPickerDidSelect(_ currency: String) {
        // This is a simple implementation - in production, you'd differentiate between from/to
        if selectedFromCurrency == "EUR" {
            selectedFromCurrency = currency
            fromCurrencyButton.setTitle("From: \(currency)", for: .normal)
        } else {
            selectedToCurrency = currency
            toCurrencyButton.setTitle("To: \(currency)", for: .normal)
        }
        updateExchangeRateDisplay()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension CurrencyExchangeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getTransactionHistory().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath)
        let transaction = viewModel.getTransactionHistory()[indexPath.row]
        cell.textLabel?.text = transaction.description
        cell.textLabel?.font = UIFont.systemFont(ofSize: 12)
        cell.textLabel?.textColor = .systemGray
        return cell
    }
}
