//
//  CurrencyExchangeExamApp.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    // iOS 12 and earlier window (kept for compatibility)
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Nothing to do here; SceneDelegate will configure the window for iOS 13+
        return true
    }

    // MARK: - UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)

        // Create persistence and manager and inject them into the initial view model
        // Explicitly specify the on-disk store name and disable in-memory mode for the app
        let persistence = CoreDataPersistenceService(storeName: "CurrencyExchangeModel", inMemory: false)
        let manager = CurrencyExchangeManager(persistenceService: persistence)
        let viewModel = BalancesViewModel(manager: manager)

        // Network monitor is shared and injected into view controllers that need it
        let networkMonitor = NetworkMonitor()
        let rootVC = BalancesViewController(viewModel: viewModel, networkMonitor: networkMonitor)
        let nav = UINavigationController(rootViewController: rootVC)
        window.rootViewController = nav
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}

