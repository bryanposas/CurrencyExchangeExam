//
//  CoreDataPersistenceService.swift
//  CurrencyExchangeExam
//
//  Created by Automated Agent on 6/10/26.
//
//  Core Data backed implementation of the `Persisting` protocol.
//  Uses a programmatically constructed model so no .xcdatamodeld is required.

import Foundation
import CoreData

// MARK: - PersistenceProtocol

/// Protocol describing persistence operations for account balances and transactions.
protocol PersistenceProtocol {
    func saveBalances(_ balances: [String: Double]) throws
    func loadBalances() -> [String: Double]
    func saveTransactionHistory(_ transactions: [ExchangeTransaction]) throws
    func loadTransactionHistory() -> [ExchangeTransaction]
    func clearAll()
}

@objcMembers
final class CoreDataPersistenceService: NSObject, PersistenceProtocol {
    // MARK: - Core Data stack
    private let container: NSPersistentContainer

    /// - Parameters:
    ///   - storeName: filename / container name
    ///   - inMemory: when true, uses an in-memory store (useful for tests)
    ///   - autoMigrate: when true, enables lightweight migration options
    init(storeName: String = "CurrencyExchangeModel", inMemory: Bool = false, autoMigrate: Bool = true) {
        let model = CoreDataPersistenceService.makeModel()
        container = NSPersistentContainer(name: storeName, managedObjectModel: model)

        // Configure store description
        let description: NSPersistentStoreDescription
        if inMemory {
            description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
        } else {
            let storeURL = CoreDataPersistenceService.defaultStoreURL(storeName: storeName)
            description = NSPersistentStoreDescription(url: storeURL)
            description.type = NSSQLiteStoreType
        }

        // Lightweight migration options
        if autoMigrate {
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        }

        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in
            if let err = error { loadError = err }
        }
        if let err = loadError {
            // If store cannot be loaded, fallback to in-memory store
            print("Failed to load Core Data store: \(err). Falling back to in-memory store.")
            let memDesc = NSPersistentStoreDescription()
            memDesc.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [memDesc]
            container.loadPersistentStores { _, error in
                if let e = error { fatalError("Failed to load in-memory store: \(e)") }
            }
        }
    }

    // MARK: - Model
    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Balance entity
        let balanceEntity = NSEntityDescription()
        balanceEntity.name = "CDBalance"
        balanceEntity.managedObjectClassName = "NSManagedObject"

        let currencyAttr = NSAttributeDescription()
        currencyAttr.name = "currency"
        currencyAttr.attributeType = .stringAttributeType
        currencyAttr.isOptional = false

        let balanceAttr = NSAttributeDescription()
        balanceAttr.name = "balance"
        balanceAttr.attributeType = .doubleAttributeType
        balanceAttr.isOptional = false

        balanceEntity.properties = [currencyAttr, balanceAttr]

        // Transaction entity
        let txEntity = NSEntityDescription()
        txEntity.name = "CDTransaction"
        txEntity.managedObjectClassName = "NSManagedObject"

        func makeStringAttr(_ name: String) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = name
            a.attributeType = .stringAttributeType
            a.isOptional = false
            return a
        }

        func makeDoubleAttr(_ name: String) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = name
            a.attributeType = .doubleAttributeType
            a.isOptional = false
            return a
        }

        let fromCurrency = makeStringAttr("fromCurrency")
        let toCurrency = makeStringAttr("toCurrency")
        let fromAmount = makeDoubleAttr("fromAmount")
        let toAmount = makeDoubleAttr("toAmount")
        let exchangeRate = makeDoubleAttr("exchangeRate")

        let timestamp = NSAttributeDescription()
        timestamp.name = "timestamp"
        timestamp.attributeType = .dateAttributeType
        timestamp.isOptional = false

        let commission = makeDoubleAttr("commissionAmount")

        txEntity.properties = [fromCurrency, toCurrency, fromAmount, toAmount, exchangeRate, timestamp, commission]

        model.entities = [balanceEntity, txEntity]
        return model
    }

    private static func defaultStoreURL(storeName: String) -> URL {
        let fm = FileManager.default
        let appSupport = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = appSupport ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dbURL = dir.appendingPathComponent("\(storeName).sqlite")
        return dbURL
    }

    // MARK: - PersistenceProtocol
    func saveBalances(_ balances: [String: Double]) throws {
        let ctx = container.viewContext
        try ctx.performAndWait {
            let fetch = NSFetchRequest<NSManagedObject>(entityName: "CDBalance")
            let existing = try ctx.fetch(fetch)
            existing.forEach { ctx.delete($0) }

            for (currency, amount) in balances {
                let obj = NSEntityDescription.insertNewObject(forEntityName: "CDBalance", into: ctx)
                obj.setValue(currency, forKey: "currency")
                obj.setValue(amount, forKey: "balance")
            }
            if ctx.hasChanges { try ctx.save() }
        }
    }

    func loadBalances() -> [String: Double] {
        let ctx = container.viewContext
        var result: [String: Double] = [:]
        ctx.performAndWait {
            let fetch = NSFetchRequest<NSManagedObject>(entityName: "CDBalance")
            do {
                let records = try ctx.fetch(fetch)
                for rec in records {
                    if let currency = rec.value(forKey: "currency") as? String,
                       let balance = rec.value(forKey: "balance") as? Double {
                        result[currency] = balance
                    }
                }
            } catch {
                print("CoreData: failed to fetch balances: \(error)")
            }
        }
        return result
    }

    func saveTransactionHistory(_ transactions: [ExchangeTransaction]) throws {
        let ctx = container.viewContext
        try ctx.performAndWait {
            let fetch = NSFetchRequest<NSManagedObject>(entityName: "CDTransaction")
            let existing = try ctx.fetch(fetch)
            existing.forEach { ctx.delete($0) }

            for tx in transactions {
                let obj = NSEntityDescription.insertNewObject(forEntityName: "CDTransaction", into: ctx)
                obj.setValue(tx.fromCurrency, forKey: "fromCurrency")
                obj.setValue(tx.toCurrency, forKey: "toCurrency")
                obj.setValue(tx.fromAmount, forKey: "fromAmount")
                obj.setValue(tx.toAmount, forKey: "toAmount")
                obj.setValue(tx.exchangeRate, forKey: "exchangeRate")
                obj.setValue(tx.timestamp, forKey: "timestamp")
                obj.setValue(tx.commissionAmount, forKey: "commissionAmount")
            }
            if ctx.hasChanges { try ctx.save() }
        }
    }

    func loadTransactionHistory() -> [ExchangeTransaction] {
        let ctx = container.viewContext
        var result: [ExchangeTransaction] = []
        ctx.performAndWait {
            let fetch = NSFetchRequest<NSManagedObject>(entityName: "CDTransaction")
            // sort by timestamp desc
            let sort = NSSortDescriptor(key: "timestamp", ascending: false)
            fetch.sortDescriptors = [sort]
            do {
                let records = try ctx.fetch(fetch)
                for rec in records {
                    guard
                        let fromCurrency = rec.value(forKey: "fromCurrency") as? String,
                        let toCurrency = rec.value(forKey: "toCurrency") as? String,
                        let fromAmount = rec.value(forKey: "fromAmount") as? Double,
                        let toAmount = rec.value(forKey: "toAmount") as? Double,
                        let exchangeRate = rec.value(forKey: "exchangeRate") as? Double,
                        let timestamp = rec.value(forKey: "timestamp") as? Date,
                        let commission = rec.value(forKey: "commissionAmount") as? Double
                    else { continue }

                    let tx = ExchangeTransaction(
                        fromCurrency: fromCurrency,
                        toCurrency: toCurrency,
                        fromAmount: fromAmount,
                        toAmount: toAmount,
                        exchangeRate: exchangeRate,
                        timestamp: timestamp,
                        commissionAmount: commission
                    )
                    result.append(tx)
                }
            } catch {
                print("CoreData: failed to fetch transactions: \(error)")
            }
        }
        return result
    }

    func clearAll() {
        let ctx = container.viewContext
        ctx.performAndWait {
            do {
                let balances = try ctx.fetch(NSFetchRequest<NSManagedObject>(entityName: "CDBalance"))
                balances.forEach { ctx.delete($0) }
                let txs = try ctx.fetch(NSFetchRequest<NSManagedObject>(entityName: "CDTransaction"))
                txs.forEach { ctx.delete($0) }
                if ctx.hasChanges { try ctx.save() }
            } catch {
                print("CoreData: failed to clear store: \(error)")
            }
        }
    }
}
