//
//  BalanceCardView.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import UIKit

/// Custom view displaying currency balance
final class BalanceCardView: UIView {
    // MARK: - UI Components
    private let currencyLabel = UILabel()
    private let balanceLabel = UILabel()
    private let containerView = UIView()
    
    // MARK: - Properties
    private let currency: String
    private let balance: Double
    
    // MARK: - Initialization
    init(currency: String, balance: Double) {
        self.currency = currency
        self.balance = balance
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        // Container
        containerView.backgroundColor = .systemBlue
        containerView.layer.cornerRadius = 12
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // Currency label
        currencyLabel.text = currency
        currencyLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        currencyLabel.textColor = .white
        currencyLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(currencyLabel)
        
        // Balance label
        balanceLabel.text = String(format: "%.2f", balance)
        balanceLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        balanceLabel.textColor = .white
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(balanceLabel)
        
        // Layout
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            // Currency label
            currencyLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            currencyLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            // Balance label
            balanceLabel.topAnchor.constraint(equalTo: currencyLabel.bottomAnchor, constant: 8),
            balanceLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            balanceLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            // Height constraint
            heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
    }
    
    // MARK: - Public Methods
    
    func updateBalance(_ newBalance: Double) {
        balanceLabel.text = String(format: "%.2f", newBalance)
    }
}
