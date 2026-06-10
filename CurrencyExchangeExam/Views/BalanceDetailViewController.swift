//
//  BalanceDetailViewController.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//
//  Displays the balance for a single currency and lists all transactions
//  involving that currency, grouped by date. Provides an entry point to
//  ExchangeViewController via the "Exchange Currency" button.
//  Displays a connectivity banner when the network is unreachable.

import UIKit

// MARK: - BalanceDetailViewController

final class BalanceDetailViewController: UIViewController {

    // MARK: - Types

    private struct TransactionRow {
        let title: String
        let subtitle: String
        let amountText: String
        let isPositive: Bool
    }

    // MARK: - UI

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let headerView = BalanceDetailHeaderView()
    private let banner = ConnectionStatusBanner()

    // MARK: - Properties

    private let currency: String
    private let viewModel: BalanceDetailViewModel
    private let networkMonitor: NetworkMonitoring
    private var networkMonitorToken: UUID?
    private var sections: [(date: String, rows: [TransactionRow])] = []

    // MARK: - Init

    init(currency: String, viewModel: BalanceDetailViewModel, networkMonitor: NetworkMonitoring) {
        self.currency = currency
        self.viewModel = viewModel
        self.networkMonitor = networkMonitor
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = currency
        view.backgroundColor = .systemGroupedBackground
        setupTableView()
        setupNetworkMonitoring()
        headerView.onExchangeTapped = { [weak self] in self?.openExchangeModal() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshBalance()
        refreshTransactions()
        if !networkMonitor.isConnected {
            banner.show(message: Strings.networkWarning, delay: 0)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeTableHeaderView()
    }

    deinit {
        if let token = networkMonitorToken {
            networkMonitor.removeObserver(id: token)
        }
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        networkMonitorToken = networkMonitor.addObserver { [weak self] isConnected in
            guard let self else { return }
            if isConnected {
                self.banner.hide()
            } else {
                self.banner.show(message: Strings.networkWarning, delay: 3.0)
            }
        }
    }

    // MARK: - Setup

    private func setupTableView() {
        // Banner at the safe-area top pushes the tableView down when it expands.
        banner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TransactionCell.self, forCellReuseIdentifier: TransactionCell.reuseID)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.tableHeaderView = headerView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: banner.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Header Sizing

    private func sizeTableHeaderView() {
        let targetSize = CGSize(
            width: tableView.bounds.width,
            height: UIView.layoutFittingCompressedSize.height
        )
        let height = headerView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        guard abs(headerView.frame.height - height) > 1 else { return }
        headerView.frame.size.height = height
        tableView.tableHeaderView = headerView
    }

    // MARK: - Data

    private func refreshBalance() {
        let balance = viewModel.getBalance(for: currency)
        headerView.configure(currency: currency, balance: balance)
    }

    private func refreshTransactions() {
        sections = grouped(transactions: viewModel.getTransactions(for: currency))
        tableView.reloadData()
    }

    private func grouped(transactions: [ExchangeTransaction]) -> [(date: String, rows: [TransactionRow])] {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        fmt.locale = Locale(identifier: "en_US_POSIX")

        var result: [(String, [TransactionRow])] = []
        var dateIndex: [String: Int] = [:]

        for tx in transactions {
            let dateKey = fmt.string(from: tx.timestamp).uppercased()
            let isOutgoing = tx.fromCurrency == currency

            let row = TransactionRow(
                title: Strings.transactionTitle,
                subtitle: isOutgoing
                    ? String(format: Strings.toFormat, tx.toCurrency)
                    : String(format: Strings.fromFormat, tx.fromCurrency),
                amountText: isOutgoing
                    ? String(format: "-%.2f %@", tx.fromAmount, currency)
                    : String(format: "+%.2f %@", tx.toAmount, currency),
                isPositive: !isOutgoing
            )

            if let idx = dateIndex[dateKey] {
                result[idx].1.append(row)
            } else {
                dateIndex[dateKey] = result.count
                result.append((dateKey, [row]))
            }
        }
        return result
    }

    // MARK: - Navigation

    private func openExchangeModal() {
        let exchangeVC = ExchangeViewController(
            viewModel: viewModel.makeExchangeViewModel(),
            initialSellCurrency: currency,
            networkMonitor: networkMonitor
        )
        exchangeVC.onExchangeCompleted = { [weak self] in
            self?.refreshBalance()
            self?.refreshTransactions()
        }
        let nav = UINavigationController(rootViewController: exchangeVC)
        nav.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            nav.sheetPresentationController?.detents = [.large()]
        }
        present(nav, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension BalanceDetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.isEmpty ? 1 : sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections.isEmpty ? 1 : sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections.isEmpty ? Strings.transactionHistoryHeader : sections[section].date
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if sections.isEmpty {
            let cell = UITableViewCell()
            cell.textLabel?.text = Strings.noTransactions
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .center
            cell.selectionStyle = .none
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TransactionCell.reuseID,
            for: indexPath
        ) as? TransactionCell else { return UITableViewCell() }

        let row = sections[indexPath.section].rows[indexPath.row]
        cell.configure(title: row.title, subtitle: row.subtitle, amount: row.amountText, isPositive: row.isPositive)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension BalanceDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
    }
}

// MARK: - Constants

private enum Strings {
    static let transactionTitle = "Currency Exchange"
    static let toFormat = "To: %@"
    static let fromFormat = "From: %@"
    static let transactionHistoryHeader = "Transaction History"
    static let noTransactions = "No transactions yet"
    static let networkWarning = "Exchange rates may not be up to date. Check your internet connection."
}

// MARK: - BalanceDetailHeaderView

private final class BalanceDetailHeaderView: UIView {

    // MARK: - Callback

    var onExchangeTapped: (() -> Void)?

    // MARK: - UI

    private let availableBalanceLabel = UILabel()
    private let amountLabel = UILabel()
    private let currencyCodeLabel = UILabel()
    private let exchangeButton = UIButton(type: .system)

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // MARK: - Public

    func configure(currency: String, balance: Double) {
        currencyCodeLabel.text = currency
        amountLabel.text = formatted(balance)
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .systemBackground

        availableBalanceLabel.text = Strings.availableBalance
        availableBalanceLabel.font = .systemFont(ofSize: 14)
        availableBalanceLabel.textColor = .secondaryLabel

        amountLabel.font = .systemFont(ofSize: 34, weight: .bold)
        amountLabel.textColor = .label
        amountLabel.adjustsFontSizeToFitWidth = true
        amountLabel.minimumScaleFactor = 0.6

        currencyCodeLabel.font = .systemFont(ofSize: 15)
        currencyCodeLabel.textColor = .secondaryLabel

        exchangeButton.setTitle(Strings.exchangeButtonTitle, for: .normal)
        exchangeButton.setTitleColor(.white, for: .normal)
        exchangeButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        exchangeButton.backgroundColor = Colors.buttonBackground
        exchangeButton.layer.cornerRadius = Layout.buttonCornerRadius
        exchangeButton.addTarget(self, action: #selector(exchangeButtonTapped), for: .touchUpInside)

        [availableBalanceLabel, amountLabel, currencyCodeLabel, exchangeButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            availableBalanceLabel.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            availableBalanceLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            amountLabel.topAnchor.constraint(equalTo: availableBalanceLabel.bottomAnchor, constant: 8),
            amountLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            amountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            amountLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),

            currencyCodeLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 4),
            currencyCodeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            exchangeButton.topAnchor.constraint(equalTo: currencyCodeLabel.bottomAnchor, constant: 24),
            exchangeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            exchangeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            exchangeButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight),
            exchangeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24)
        ])
    }

    @objc private func exchangeButtonTapped() {
        onExchangeTapped?()
    }

    private func formatted(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

// MARK: - BalanceDetailHeaderView Constants

private extension BalanceDetailHeaderView {
    enum Strings {
        static let availableBalance = "Available balance"
        static let exchangeButtonTitle = "Exchange Currency"
    }
    enum Colors {
        static let buttonBackground = UIColor(red: 0.37, green: 0.62, blue: 0.82, alpha: 0.85)
    }
    enum Layout {
        static let buttonHeight: CGFloat = 50
        static let buttonCornerRadius: CGFloat = 25
    }
}

// MARK: - TransactionCell

private final class TransactionCell: UITableViewCell {

    static let reuseID = "TransactionCell"

    // MARK: - UI

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let amountLabel = UILabel()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // MARK: - Public

    func configure(title: String, subtitle: String, amount: String, isPositive: Bool) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        amountLabel.text = amount
        amountLabel.textColor = isPositive ? .systemGreen : .systemRed
    }

    // MARK: - Setup

    private func setupUI() {
        selectionStyle = .none

        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .label

        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel

        amountLabel.font = .systemFont(ofSize: 15, weight: .medium)
        amountLabel.textAlignment = .right
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let rowStack = UIStackView(arrangedSubviews: [textStack, amountLabel])
        rowStack.axis = .horizontal
        rowStack.spacing = 8
        rowStack.alignment = .center
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rowStack)

        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            rowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            rowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            rowStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
}
