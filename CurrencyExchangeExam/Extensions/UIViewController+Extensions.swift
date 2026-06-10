//
//  UIViewController+Extensions.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import UIKit

extension UIViewController {
    /// Present an error alert to the user
    func showErrorAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default) { _ in completion?() })
        present(alert, animated: true)
    }
    
    /// Present a success alert to the user
    func showSuccessAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        present(alert, animated: true)
    }
}

extension Double {
    /// Format as currency string
    func formattedCurrency(code: String = "USD") -> String {
        return String(format: "%.2f %@", self, code)
    }
}

extension AppError: Equatable {
    public static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidResponse, .invalidResponse),
             (.invalidExchangeRate, .invalidExchangeRate),
             (.insufficientFunds, .insufficientFunds),
             (.invalidAmount, .invalidAmount),
             (.sameCurrency, .sameCurrency),
             (.apiKeyMissing, .apiKeyMissing):
            return true
        case (.networkError, .networkError),
             (.decodingError, .decodingError),
             (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
}
