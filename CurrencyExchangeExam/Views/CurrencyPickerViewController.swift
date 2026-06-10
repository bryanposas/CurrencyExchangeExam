//
//  CurrencyPickerViewController.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import UIKit

/// Protocol for currency picker delegate
protocol CurrencyPickerDelegate: AnyObject {
    func currencyPickerDidSelect(_ currency: String)
}

/// Modal view controller for selecting a currency
final class CurrencyPickerViewController: UIViewController {
    // MARK: - UI Components
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let closeButton = UIButton(type: .system)
    
    // MARK: - Properties
    private let currencies: [String]
    private weak var delegate: CurrencyPickerDelegate?
    
    // MARK: - Initialization
    init(currencies: [String], delegate: CurrencyPickerDelegate?) {
        self.currencies = currencies.sorted()
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Close button
        closeButton.setTitle("Close", for: .normal)
        closeButton.setTitleColor(.systemBlue, for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        // Table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // Layout
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 12),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension CurrencyPickerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currencies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = currencies[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCurrency = currencies[indexPath.row]
        delegate?.currencyPickerDidSelect(selectedCurrency)
        dismiss(animated: true)
    }
}
