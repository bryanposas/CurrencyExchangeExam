//
//  BalanceCardView.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//
//  Tappable card showing a single currency balance in the style of a
//  bank-account summary card (white background, subtle shadow, rounded corners).
//  Scaling to new currencies requires no code change — just pass the currency
//  code and balance at init time.

import UIKit

// MARK: - BalanceCardView

/// Displays a single currency balance as a tappable card.
/// The `onTap` closure is called when the user taps the card.
final class BalanceCardView: UIView {

    // MARK: - Callback

    /// Called when the user taps the card.
    var onTap: (() -> Void)?

    // MARK: - UI

    private let currencyNameLabel = UILabel()
    private let currencyCodeLabel = UILabel()
    private let amountLabel = UILabel()
    private let availableBalanceLabel = UILabel()

    // MARK: - Init

    init(currency: String, balance: Double) {
        super.init(frame: .zero)
        setupCard(currency: currency, balance: balance)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // MARK: - Public

    /// Updates the displayed balance amount without recreating the view.
    func updateBalance(_ balance: Double, currency: String) {
        amountLabel.text = formatted(balance, currency: currency)
    }

    // MARK: - Setup

    private func setupCard(currency: String, balance: Double) {
        backgroundColor = .systemBackground
        layer.cornerRadius = Layout.cornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 2)

        currencyNameLabel.text = fullName(for: currency)
        currencyNameLabel.font = .systemFont(ofSize: 16, weight: .bold)
        currencyNameLabel.textColor = Colors.darkTitle

        currencyCodeLabel.text = currency
        currencyCodeLabel.font = .systemFont(ofSize: 14)
        currencyCodeLabel.textColor = .secondaryLabel

        amountLabel.text = formatted(balance, currency: currency)
        amountLabel.font = .systemFont(ofSize: 26, weight: .semibold)
        amountLabel.textColor = Colors.darkTitle
        amountLabel.textAlignment = .right
        amountLabel.adjustsFontSizeToFitWidth = true
        amountLabel.minimumScaleFactor = 0.7

        availableBalanceLabel.text = Strings.availableBalance
        availableBalanceLabel.font = .systemFont(ofSize: 13)
        availableBalanceLabel.textColor = .secondaryLabel
        availableBalanceLabel.textAlignment = .right

        [currencyNameLabel, currencyCodeLabel, amountLabel, availableBalanceLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        let p = Layout.padding
        NSLayoutConstraint.activate([
            currencyNameLabel.topAnchor.constraint(equalTo: topAnchor, constant: p),
            currencyNameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            currencyNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -p),

            currencyCodeLabel.topAnchor.constraint(equalTo: currencyNameLabel.bottomAnchor, constant: 4),
            currencyCodeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),

            amountLabel.topAnchor.constraint(equalTo: currencyCodeLabel.bottomAnchor, constant: 20),
            amountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: p),
            amountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),

            availableBalanceLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 4),
            availableBalanceLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            availableBalanceLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -p)
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        isUserInteractionEnabled = true
    }

    // MARK: - Interaction

    @objc private func handleTap() { onTap?() }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.1) { self.alpha = 0.7 }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.1) { self.alpha = 1.0 }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.1) { self.alpha = 1.0 }
    }

    // MARK: - Helpers

    private func formatted(_ amount: Double, currency: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        let num = f.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        return "\(currency)  \(num)"
    }

    /// Returns a human-readable name for common ISO 4217 currency codes.
    /// Adding new currencies only requires extending this dictionary — no
    /// other code changes are needed.
    private func fullName(for code: String) -> String {
        let names: [String: String] = [
            "AED": "UAE Dirham",       "AUD": "Australian Dollar",
            "BGN": "Bulgarian Lev",    "BRL": "Brazilian Real",
            "CAD": "Canadian Dollar",  "CHF": "Swiss Franc",
            "CNY": "Chinese Yuan",     "CZK": "Czech Koruna",
            "DKK": "Danish Krone",     "EUR": "Euro",
            "GBP": "British Pound",    "HKD": "Hong Kong Dollar",
            "HUF": "Hungarian Forint", "IDR": "Indonesian Rupiah",
            "ILS": "Israeli Shekel",   "INR": "Indian Rupee",
            "JPY": "Japanese Yen",     "KRW": "South Korean Won",
            "MXN": "Mexican Peso",     "MYR": "Malaysian Ringgit",
            "NOK": "Norwegian Krone",  "NZD": "New Zealand Dollar",
            "PHP": "Philippine Peso",  "PLN": "Polish Zloty",
            "RON": "Romanian Leu",     "RUB": "Russian Ruble",
            "SEK": "Swedish Krona",    "SGD": "Singapore Dollar",
            "THB": "Thai Baht",        "TRY": "Turkish Lira",
            "USD": "US Dollar",        "ZAR": "South African Rand"
        ]
        return names[code] ?? "\(code) Account"
    }
}

// MARK: - Constants

private enum Strings {
    static let availableBalance = "Available balance"
}

private enum Colors {
    static let darkTitle = UIColor(red: 0.13, green: 0.18, blue: 0.27, alpha: 1.0)
}

private enum Layout {
    static let cornerRadius: CGFloat = 16
    static let padding: CGFloat = 20
}
