//
//  ExchangeRateService.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import Foundation

// MARK: - ExchangeRateService

/// Fetches and caches exchange rates from the remote API.
/// Delegates the actual HTTP transport to an injected NetworkClient.
class ExchangeRateService {

    // MARK: - Properties

    private let networkClient: NetworkClient
    private var currentExchangeRates: ExchangeRates?
    private var lastFetchDate: Date?

    // MARK: - Initialization

    init(networkClient: NetworkClient = URLSessionNetworkClient()) {
        self.networkClient = networkClient
    }

    // MARK: - Public Methods

    func fetchExchangeRates(completion: @escaping (Result<ExchangeRates, AppError>) -> Void) {
        guard let url = buildURL() else {
            completion(.failure(.apiKeyMissing))
            return
        }

        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: Constants.API.timeout)
        request.httpMethod = "GET"

        networkClient.perform(request: request) { [weak self] (result: Result<ExchangeRates, AppError>) in
            if case .success(let rates) = result {
                self?.currentExchangeRates = rates
                self?.lastFetchDate = Date()
            }
            completion(result)
        }
    }

    func getCachedRates() -> ExchangeRates? {
        currentExchangeRates
    }

    func shouldRefreshRates(interval: TimeInterval = Constants.API.refreshInterval) -> Bool {
        guard let lastFetch = lastFetchDate else { return true }
        return Date().timeIntervalSince(lastFetch) > interval
    }

    // MARK: - Private Methods

    private func buildURL() -> URL? {
        var components = URLComponents(string: Constants.API.baseURL + "/rates/latest")
        components?.queryItems = [URLQueryItem(name: "apikey", value: Constants.API.apiKey)]
        return components?.url
    }
}
