//
//  Migrations.swift
//  SerializableDataDemo
//
//  Created by Emily Ivie on 2/9/17.

//  Based on https://gist.github.com/kean/28439b29532993b620497621a4545789
//  Copyright (c) 2016 Alexander Grebenyuk (github.com/kean).
//  The MIT License (MIT)
//

import Foundation
import CoreData

struct Migrations {

    enum MigrationError: String, Error {
        case missingOriginalStore = "Original store not found"
        case incompatibleModels = "Incompatible models"
        case missingModels = "Model not found"
    }
    
    private let storeName: String
    private let storeUrl: URL
    
    init(storeName: String, storeUrl: URL) {
        self.storeName = storeName
        self.storeUrl = storeUrl
    }
    
    func run(migrationNames: [String]) throws {
        let storeDirectory = Bundle.main.url(forResource: storeName, withExtension: "momd")?.lastPathComponent
        var migrationMoms = try migrationNames.flatMap {
            return try managedObjectModel(forName: $0, bundle: Bundle.main, directory: storeDirectory)
        }
        migrationMoms = try reduceMomsToPendingChanges(moms: migrationMoms)
        if migrationMoms.count > 1, let startMom = migrationMoms.first {
            _ = try migrationMoms[1..<migrationMoms.count].reduce(startMom) { (sourceMom, destinationMom) in
                try migrateStore(from: sourceMom, to: destinationMom)
                return destinationMom
            }
        }
    }
    
    private func managedObjectModel(
        forName name: String,
        bundle: Bundle,
        directory: String?
    ) throws -> NSManagedObjectModel? {
        let omoUrl = bundle.url(forResource: name, withExtension: "omo", subdirectory: directory)
        let momUrl = bundle.url(forResource: name, withExtension: "mom", subdirectory: directory)
        guard let url = omoUrl ?? momUrl else {
            if directory != nil {
                return try managedObjectModel(forName: name, bundle: bundle, directory: nil)
            } else {
                throw MigrationError.missingModels
            }
        }
        return NSManagedObjectModel(contentsOf: url)
    }

    private func reduceMomsToPendingChanges(moms: [NSManagedObjectModel]) throws -> [NSManagedObjectModel] {
        let meta = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeUrl)
        guard let index = moms.index(where: {
            $0.isConfiguration(withName: nil, compatibleWithStoreMetadata: meta)
        }) else {
            throw MigrationError.incompatibleModels
        }
        return Array(moms[index..<moms.count])
    }
    
    private func migrateStore(
        from sourceMom: NSManagedObjectModel,
        to destinationMom: NSManagedObjectModel
    ) throws {
        // Prepare temp directory
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        defer {
            _ = try? FileManager.default.removeItem(at: dir)
        }

        // Perform migration
        let mapping = try findMapping(from: sourceMom, to: destinationMom)
        let destinationUrl = dir.appendingPathComponent(storeUrl.lastPathComponent)
        let manager = NSMigrationManager(sourceModel: sourceMom, destinationModel: destinationMom)
        try autoreleasepool {
            try manager.migrateStore(
                from: storeUrl,
                sourceType: NSSQLiteStoreType,
                options: nil,
                with: mapping,
                toDestinationURL: destinationUrl,
                destinationType: NSSQLiteStoreType,
                destinationOptions: nil
            )
        }

        // Replace source store
        let psc = NSPersistentStoreCoordinator(managedObjectModel: destinationMom)
        try psc.replacePersistentStore(
            at: storeUrl,
            destinationOptions: nil,
            withPersistentStoreFrom: destinationUrl,
            sourceOptions: nil,
            ofType: NSSQLiteStoreType
        )
    }
    
    private func findMapping(
        from sourceMom: NSManagedObjectModel,
        to destinationMom: NSManagedObjectModel
    ) throws -> NSMappingModel {
        if let mapping = NSMappingModel(from: Bundle.allBundles, forSourceModel: sourceMom, destinationModel: destinationMom) {
            return mapping // found custom mapping
        }
        return try NSMappingModel.inferredMappingModel(forSourceModel: sourceMom, destinationModel: destinationMom)
    }
    
    private func remove(oldStoreUrl: URL?) -> Bool {
        guard let oldStoreUrl = oldStoreUrl else { return true }
        do {
            try FileManager.default.removeItem(at: oldStoreUrl)
            return true
        } catch {
            print("Failed to delete old store")
        }
        return false
    }
}
