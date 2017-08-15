//
//  CodableCoreDataManageable.swift
//
//  Copyright 2017 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.

import CoreData

/// Abstracted JSONDecoder to just the method we need
/// (so we could use any special configuration model created just for our app)
public protocol CodableDecoder {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable
}

/// Abstracted JSONEncoder to just the method we need
/// (so we could use any special configuration model created just for our app)
public protocol CodableEncoder {
    func encode<T>(_ value: T) throws -> Data where T : Encodable
}

/// Basic protocol requirements for our manager
/// (most functionality is provided by default in extension)
public protocol CodableCoreDataManageable: SimpleCoreDataManageable {

    /// Required: Decoder initialized with correct configuration (date, etc)
    var decoder: CodableDecoder { get }

    /// Required: Encoder initialized with correct configuration (date, etc)
    var encoder: CodableEncoder { get }

}

extension CodableCoreDataManageable {
    /// The closure type for editing fetch requests.
    /// (Duplicate these per file or use Whole Module Optimization, which is slow in dev)
    public typealias AlterFetchRequest<T: NSManagedObject> = ((NSFetchRequest<T>) -> Void)

    /// Retrieve single row with criteria closure.
    public func getValue<T: CodableCoreDataStorable>(
        alterFetchRequest: @escaping AlterFetchRequest<T.EntityType>
    ) -> T? {
        var result: T?
        if let data: Data = self.getOneTransformed(
            transformEntity: { $0.value(forKey: T.serializedDataKey) as? Data },
            alterFetchRequest: alterFetchRequest
        ) {
            do {
                result = try decoder.decode(T.self, from: data)
            } catch let decodeError {
                print("Error: decoding failed for \(T.self): \(decodeError)")
            }
        }
        return result
    }

    /// Retrieve object row with criteria closure.
    public func getObject<T: CodableCoreDataStorable>(
        item: T
    ) -> T.EntityType? {
        return getOne { (fetchRequest: NSFetchRequest<T.EntityType>) in
            item.setIdentifyingPredicate(fetchRequest: fetchRequest)
        }
    }

    /// Retrieve multiple rows with criteria closure.
    public func getAllValues<T: CodableCoreDataStorable>(
        alterFetchRequest: @escaping AlterFetchRequest<T.EntityType>
    ) -> [T] {
        var result: [T] = []
        let data: [Data] = self.getAllTransformed(
            transformEntity: { $0.value(forKey: T.serializedDataKey) as? Data },
            alterFetchRequest: alterFetchRequest
        )
        result = data.map { row -> T? in
            do {
                return try decoder.decode(T.self, from: row)
            } catch let decodeError {
                print("Error: decoding failed for \(T.self): \(decodeError)")
            }
            return nil
        }.filter({  $0 != nil }).map({ $0! })
        return result
    }

    /// Save a single row of a CoreDataStorable object.
    public func saveValue<T: CodableCoreDataStorable>(
        item: T
    ) -> Bool {
        return saveAllValues(items: [item])
    }

    /// Save multiple rows.
    public func saveAllValues<T: CodableCoreDataStorable>(
        items: [T]
    ) -> Bool {
        guard !items.isEmpty else { return true }
        var result: Bool = false
        let waitForEndTask = DispatchWorkItem {} // semaphore flag
        persistentContainer.performBackgroundTask { moc in
            defer { waitForEndTask.perform() }
            moc.automaticallyMergesChangesFromParent = true
            moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            // release any objective-c objects
            autoreleasepool {
                for item in items {
                    let coreItem = item.entity(context: moc) ?? T.EntityType(context: moc)
                    item.setColumnsOnSave(coreItem: coreItem)
                }
            }
            do {
                try moc.save()
                result = true
            } catch let saveError as NSError {
                print("Error: save failed for \(T.self): \(saveError)")
            }
        }
        waitForEndTask.wait()
        return result
    }

    /// Delete single row of a CoreDataStorable object.
    public func deleteValue<T: CodableCoreDataStorable>(
        item: T
    ) -> Bool {
        return deleteAll { (fetchRequest: NSFetchRequest<T.EntityType>) in
            item.setIdentifyingPredicate(fetchRequest: fetchRequest)
        }
    }
}
