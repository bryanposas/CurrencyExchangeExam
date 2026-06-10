//
//  NetworkClient.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import Foundation

// MARK: - Protocol

/// Abstracts the transport layer so services remain testable without real network calls.
protocol NetworkClient {
    func perform<T: Decodable>(request: URLRequest, completion: @escaping (Result<T, AppError>) -> Void)
}

// MARK: - URLSessionNetworkClient

/// Production implementation backed by URLSession.
final class URLSessionNetworkClient: NetworkClient {

    // MARK: - Properties

    private let session: URLSession

    // MARK: - Initialization

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - NetworkClient

    func perform<T: Decodable>(request: URLRequest, completion: @escaping (Result<T, AppError>) -> Void) {
        let task = session.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            do {
                completion(.success(try JSONDecoder().decode(T.self, from: data)))
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }
        task.resume()
    }
}
