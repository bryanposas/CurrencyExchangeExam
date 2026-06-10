//
//  BalanceDetailViewController.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//
//  Displays the balance for a single currency and lists all transactions
//  involving that currency, grouped by date. Provides an entry point to
//  ExchangeViewController via the "Exchange Currency" button.
//
//  Design notes:
//  - Pulls balance and transaction data from the shared ViewModel on every
//    viewWillAppear, so it always reflects exchanges performed in the modal.
//  - Does NOT become the viewModel delegate — data is read via direct calls,
//    keeping the delegate chain simple (ExchangeViewController owns it while
//    the modal is visible; BalancesViewController owns it otherwise).

import UIKit

// MARK: - BalanceDetailViewController

/// Detail screen for a single currency: shows available balance, an exchange
/// button, and a chronological transaction history.
final class BalanceDetailViewController: UIViewController {

    // MARK: - Types

    /// Flat representation of a transaction row for display purposes.
    private struct TransactionRow {
        let title: String
        let subtitle: String
        let amountText: String
        let isPositive: Bool
    }

    // MARK: - UI

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let headerView = BalanceDetailHeaderView()

    // MARK: - Properties

    private let currency: String
    private let viewModel: CurrencyExchangeViewModel

    /// Transactions grouped by formatted date string, e.g. [("JUN 10", [rows...])].
    private var sections: [(date: String, rows: [TransactionRow])] = []

    // MARK: - Init

    init(currency: String, viewModel: CurrencyExchangeViewModel) {
        self.currency = currency
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = currency
        view.backgroundColor = .systemGroupedBackground
        setupTableView()
        headerView.onExchangeTapped = { [weak self] in self?.openExchangeModal() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Pull latest data every time this screen becomes visible —
        // covers the case where the exchange modal just completed a trade.
        refreshBalance()
        refreshTransactions()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeTableHeaderView()
    }

    // MARK: - Setup

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TransactionCell.self, forCellReuseIdentifier: TransactionCell.reuseID)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.tableHeaderView = headerView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Header Sizing

    /// Recalculates the tableHeaderView height using Auto Layout so the header
    /// grows/shrinks correctly across device sizes without hardcoded heights.
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
        let all = viewModel.getTransactionHistory()
        let relevant = all.filter { $0.fromCurrency == currency || $0.toCurrency == currency }
        sections = grouped(transactions: relevant)
        tableView.reloadData()
    }

    /// Groups a flat list of transactions into date-keyed sections.
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
        let exchangeVC = ExchangeViewController(viewModel: viewModel, initialSellCurrency: currency)
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
        return sections.isEmpty ? 1 : sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections.isEmpty ? 1 : sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections.isEmpty ? Strings.transactionHistoryHeader : sections[section].date
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
        return false
    }
}

// MARK: - Constants

private enum Strings {
    static let transactionTitle = "Currency Exchange"
    static let toFormat = "To: %@"
    static let fromFormat = "From: %@"
    static let transactionHistoryHeader = "Transaction History"
    static let noTransactions = "No transactions yet"
}

// MARK: - BalanceDetailHeaderView

/// Header view embedded as UITableView.tableHeaderView.
/// Shows the balance and an exchange entry button.
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

        let p = Layout.padding
        NSLayoutConstraint.activate([
            availableBalanceLabel.topAnchor.constraint(equalTo: topAnchor, constant: p),
            availableBalanceLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),

            amountLabel.topAnchor.constraint(equalTo: availableBalanceLabel.bottomAnchor, constant: 4),
            amountLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            amountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),

            currencyCodeLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 4),
            currencyCodeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),

            exchangeButton.topAnchor.constraint(equalTo: currencyCodeLabel.bottomAnchor, constant: 24),
            exchangeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            exchangeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            exchangeButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight),
            exchangeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p)
        ])
    }

    @objc private func exchangeButtonTapped() { onExchangeTapped?() }

    private func formatted(_ amount: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
    }

    // MARK: - Constants

    private enum Strings {
        static let availableBalance = "Available balance"
        static let exchangeButtonTitle = "Exchange Currency"
    }

    private enum Colors {
        static let buttonBackground = UIColor(red: 0.37, green: 0.62, blue: 0.82, alpha: 1.0)
    }

    private enum Layout {
        static let padding: CGFloat = 20
        static let buttonHeight: CGFloat = 50
        static let buttonCornerRadius: CGFloat = 12
    }
}

// MARK: - TransactionCell

/// Table view cell displaying a single transaction row: title, subtitle, and amount.
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
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        [titleLabel, subtitleLabel, amountLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -8),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -8),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            amountLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            amountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
}
