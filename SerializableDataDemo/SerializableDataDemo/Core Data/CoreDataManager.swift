//
//  CoreDataManager.swift
//
//  Copyright 2017 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.

import CoreData

/// Manages the storage and retrieval of CoreDataStorable/SerializableData objects.
public struct CoreDataManager: CoreDataManageable {

    public static let defaultStoreName = "SerializableDataDemo"
    public static var current: CoreDataManager = CoreDataManager(storeName: defaultStoreName)
    
    public static var isConfineToMemoryStore: Bool = false // set to true for testing
    public static var isManageMigrations: Bool = true // we manage migrations
    
    public let storeName: String
    public let serializedDataKey = "serializedData"
    public let persistentContainer: NSPersistentContainer
    public let specificContext: NSManagedObjectContext?
    
    public init(storeName: String?, context: NSManagedObjectContext?) {
        self.storeName = storeName ?? CoreDataManager.defaultStoreName
        self.specificContext = context
        if let storeName = storeName {
            self.persistentContainer = NSPersistentContainer(name: storeName)
            initContainer()
        } else {
            persistentContainer = CoreDataManager.current.persistentContainer
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

