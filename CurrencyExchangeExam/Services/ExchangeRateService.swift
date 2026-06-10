//
//  ExchangeRateService.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import Foundation

/// Service for fetching exchange rates from the API
class ExchangeRateService {
    // MARK: - Constants
    private enum Constants {
        static let apiKey = "ae277159399e4d0eadfb4903b20ca5aa"
        static let baseURL = "https://api.currencyfreaks.com/v2.0/rates/latest"
        static let timeout: TimeInterval = 15
    }
    
    // MARK: - Properties
    private let session: URLSession
    private var currentExchangeRates: ExchangeRates?
    private var lastFetchDate: Date?
    
    // MARK: - Initialization
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Public Methods
    
    /// Fetch the latest exchange rates from the API
    /// - Parameter completion: Closure called with result (rates or error)
    func fetchExchangeRates(completion: @escaping (Result<ExchangeRates, AppError>) -> Void) {
        guard let url = buildURL() else {
            completion(.failure(.apiKeyMissing))
            return
        }
        
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: Constants.timeout)
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let rates = try decoder.decode(ExchangeRates.self, from: data)
                self?.currentExchangeRates = rates
                self?.lastFetchDate = Date()
                completion(.success(rates))
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }
        
        task.resume()
    }
    
    /// Get cached exchange rates if available
    func getCachedRates() -> ExchangeRates? {
        return currentExchangeRates
    }
    
    /// Check if rates need refreshing (older than the specified interval)
    func shouldRefreshRates(interval: TimeInterval = 300) -> Bool {
        guard let lastFetch = lastFetchDate else { return true }
        return Date().timeIntervalSince(lastFetch) > interval
    }
    
    // MARK: - Private Methods
    
    /// Build the API request URL
    private func buildURL() -> URL? {
        var components = URLComponents(string: Constants.baseURL)
        components?.queryItems = [
            URLQueryItem(name: "apikey", value: Constants.apiKey)
        ]
        return components?.url
    }
}
