//
//  AppError.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import Foundation

/// Comprehensive error handling for the application
enum AppError: LocalizedError {
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case invalidExchangeRate
    case insufficientFunds
    case invalidAmount
    case sameCurrency
    case apiKeyMissing
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .invalidExchangeRate:
            return "Unable to determine exchange rate"
        case .insufficientFunds:
            return "Insufficient funds for this exchange"
        case .invalidAmount:
            return "Please enter a valid amount"
        case .sameCurrency:
            return "Source and target currencies must be different"
        case .apiKeyMissing:
            return "API key not configured"
        case .unknown(let error):
            return "An error occurred: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again"
        case .invalidResponse, .decodingError:
            return "The server response was invalid. Please try again later"
        case .insufficientFunds:
            return "You don't have enough balance to perform this exchange"
        case .invalidAmount:
            return "Amount must be greater than 0"
        case .sameCurrency:
            return "Select different currencies"
        default:
            return "Please try again"
        }
    }
}
