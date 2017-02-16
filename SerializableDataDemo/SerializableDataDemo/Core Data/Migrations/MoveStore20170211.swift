//
//  MoveStore20170211.swift
//
//  Copyright 2017 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.

import CoreData

struct MoveStore20170211 {
    
    let oldStoreName = "SingleViewCoreData"
    let newStoreName = "SerializableDataDemo"
    
    public enum MoveStoreError: Error {
        case failedToCreateStoreUrls
    }

    public func run() throws {
        let fileManager = FileManager.default
        guard let oldStoreUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("\(oldStoreName).sqlite"),
            let newStoreUrl = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("\(newStoreName).sqlite")
        else {
            throw MoveStoreError.failedToCreateStoreUrls
        }
        try migrateStoreToNewLocation(oldStoreUrl: oldStoreUrl, newStoreUrl: newStoreUrl)
    }
    
    private func migrateStoreToNewLocation(oldStoreUrl: URL, newStoreUrl: URL) throws {
        // fileExists does not work here :( - always returns false
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: oldStoreUrl.path) && !fileManager.fileExists(atPath: newStoreUrl.path) else { return }
        if let storeDirectory = Bundle.main.url(forResource: newStoreName, withExtension: "momd")?.lastPathComponent,
            let modelURL = Bundle.main.url(forResource: "SerializableDataDemo", withExtension: "mom", subdirectory: storeDirectory),
            let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
            // create new folder, if needed
            let newStorePath = newStoreUrl.deletingLastPathComponent()
            try fileManager.createDirectory(at: newStorePath, withIntermediateDirectories: true, attributes: nil)
            try persistentStoreCoordinator.replacePersistentStore(at: newStoreUrl, destinationOptions: nil, withPersistentStoreFrom: oldStoreUrl, sourceOptions: nil, ofType: NSSQLiteStoreType)
            // Remove old store
            // return here if you are experimenting, because otherwise you have to start over from scratch.
//            try? persistentStoreCoordinator.destroyPersistentStore(at: oldStoreUrl, ofType: NSSQLiteStoreType, options: nil) // does not fully delete
            try? fileManager.removeItem(at: oldStoreUrl)
            try? fileManager.removeItem(at: oldStoreUrl.appendingPathComponent("-shm"))
            try? fileManager.removeItem(at: oldStoreUrl.appendingPathComponent("-wal"))
        }
    }

}
