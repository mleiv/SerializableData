//
//  SimpleCoreDataManager.swift
//
//  Copyright 2017 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.

import CoreData

struct SimpleCoreDataManager: SimpleSerializedCoreDataManageable {

    public static let defaultStoreName = "SerializableDataDemo"
    public var serializedDataKey: String { return "serializedData" }
    
    public static var current: SimpleCoreDataManageable { return serializableCurrent }
    public static var serializableCurrent: SimpleSerializedCoreDataManageable = SimpleCoreDataManager(storeName: defaultStoreName)

    public static var isManageMigrations: Bool = true // we manage migrations
    
    public let storeName: String
    public let persistentContainer: NSPersistentContainer
    public let specificContext: NSManagedObjectContext?
    
    public init() {
        self.init(storeName: SimpleCoreDataManager.defaultStoreName)
    }
    
    public init(storeName: String?, context: NSManagedObjectContext?, isConfineToMemoryStore: Bool) {
        self.storeName = storeName ?? SimpleCoreDataManager.defaultStoreName
        self.specificContext = context
        if let storeName = storeName {
            self.persistentContainer = NSPersistentContainer(name: storeName)
            initContainer(isConfineToMemoryStore: isConfineToMemoryStore)
        } else {
            persistentContainer = SimpleCoreDataManager.current.persistentContainer
        }
    }
    
    public func runMigrations(storeUrl: URL) {
        do {
            try MoveStore20170211().run() // special case because I made a dumb mistake
            try CoreDataStructuralMigrations(storeName: storeName, storeUrl: storeUrl).run()
        } catch {
            fatalError("Could not run migrations \(error)")
        }
    }
}
