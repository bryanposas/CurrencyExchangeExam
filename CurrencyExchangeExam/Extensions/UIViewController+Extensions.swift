//
//  UIViewController+Extensions.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import UIKit

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
