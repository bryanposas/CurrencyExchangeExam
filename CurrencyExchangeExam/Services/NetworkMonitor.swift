//
//  NetworkMonitor.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import Network
import Foundation

// MARK: - Protocol

/// Abstracts network reachability so ViewControllers can be tested without real network events.
protocol NetworkMonitoring: AnyObject {
    /// `true` when the device has a usable network path.
    var isConnected: Bool { get }

    /// Registers a closure that fires on the main queue whenever connectivity changes.
    /// Returns a token that must be passed to `removeObserver(id:)` to unregister.
    @discardableResult
    func addObserver(_ onChange: @escaping (Bool) -> Void) -> UUID

    /// Removes the observer registered for the given token.
    func removeObserver(id: UUID)
}

// MARK: - NetworkMonitor

/// Production implementation backed by `NWPathMonitor`.
/// Create once (e.g., in SceneDelegate), then inject into ViewControllers.
/// Multiple observers are supported; each receives callbacks independently.
final class NetworkMonitor: NetworkMonitoring {

    // MARK: - Properties

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.currencyexchange.network", qos: .background)
    private var observers: [UUID: (Bool) -> Void] = [:]
    private(set) var isConnected: Bool = true

    // MARK: - Initialization

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let connected = path.status == .satisfied
            self.isConnected = connected
            DispatchQueue.main.async {
                self.observers.values.forEach { $0(connected) }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - NetworkMonitoring

    @discardableResult
    func addObserver(_ onChange: @escaping (Bool) -> Void) -> UUID {
        let id = UUID()
        observers[id] = onChange
        return id
    }

    func removeObserver(id: UUID) {
        observers.removeValue(forKey: id)
    }
}
