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
        static let apiKey: String = {
            guard let key = Bundle.main.object(forInfoDictionaryKey: "CurrencyAPIKey") as? String,
                  !key.isEmpty, key != "your_api_key_here" else {
                fatalError("CurrencyAPIKey missing. Copy Secrets.xcconfig.example → Secrets.xcconfig and add your key.")
            }
            return key
        }()
        static let timeout: TimeInterval = 15
        static let refreshInterval: TimeInterval = 300 // 5 minutes
    }
    
    enum Account {
        static let initialBalance: Double = 1000
        static let initialFromCurrency = "USD"
        static let initialCurrency = "EUR"
        static let commissionRate: Double = 0.01 // 1% commission
    }
    
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let padding: CGFloat = 16
        static let standardSpacing: CGFloat = 12
    }
}
