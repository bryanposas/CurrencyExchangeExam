//
//  Constants.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import Foundation

/// Application-wide constants
enum Constants {
    enum API {
        static let baseURL = "https://api.currencyfreaks.com/v2.0"
        static let apiKey = "ae277159399e4d0eadfb4903b20ca5aa"
        static let timeout: TimeInterval = 15
        static let refreshInterval: TimeInterval = 300 // 5 minutes
    }
    
    enum Account {
        static let initialBalance: Double = 1000
        static let initialCurrency = "USD"
        static let commissionRate: Double = 0.01
    }
    
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let padding: CGFloat = 16
        static let standardSpacing: CGFloat = 12
    }
}
