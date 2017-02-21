//
//  SimpleSerializedCoreDataManageable.swift
//
//  Copyright 2017 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.

import CoreData

public protocol SimpleSerializedCoreDataManageable: SimpleCoreDataManageable {
    var serializedDataKey: String { get }
}

extension SimpleSerializedCoreDataManageable {
    public typealias AlterFetchRequest<T: NSManagedObject> = ((NSFetchRequest<T>)->Void)
    
    /// Retrieve single row with criteria closure.
    public func getValue<T: SimpleSerializedCoreDataStorable>(
        alterFetchRequest: @escaping AlterFetchRequest<T.EntityType>
    ) -> T? {
        var result: T?
        autoreleasepool {
            if let coreItem = getOne(alterFetchRequest: alterFetchRequest),
                let serializedData = coreItem.value(forKey: self.serializedDataKey) as? Data,
                let item = T(serializedData: serializedData) {
                result = item
            }
        }
        return result
    }
    
    /// Retrieve object row with criteria closure.
    public func getObject<T: SimpleSerializedCoreDataStorable>(
        item: T
//        completion: @escaping GetObjectCompletion<T.EntityType>
    ) -> T.EntityType? {
        return getOne { (fetchRequest: NSFetchRequest<T.EntityType>) in
            item.setIdentifyingPredicate(fetchRequest: fetchRequest)
        }
    }
    
    /// Retrieve multiple rows with criteria closure.
    public func getAllValues<T: SimpleSerializedCoreDataStorable>(
        alterFetchRequest: @escaping AlterFetchRequest<T.EntityType>
    ) -> [T] {
        var result: [T] = []
        autoreleasepool {
            let coreItems: [T.EntityType] = getAll(alterFetchRequest: alterFetchRequest)
            for coreItem in coreItems {
                if let serializedData = coreItem.value(forKey: self.serializedDataKey) as? Data,
                   let t = T(serializedData: serializedData) {
                    result.append(t)
                }
            }
        }
        return result
    }

    /// Save a single row of a CoreDataStorable object.
    public func saveValue<T: SimpleSerializedCoreDataStorable>(
        item: T
    ) -> Bool {
        return saveAllValues(items: [item])
    }

    /// Save multiple rows.
    public func saveAllValues<T: SimpleSerializedCoreDataStorable>(
        items: [T]
    ) -> Bool {
        guard !items.isEmpty else { return true }
        var result: Bool = false
        let waitForEndTask = DispatchWorkItem() {} // semaphore flag
        persistentContainer.performBackgroundTask { moc in
            defer { waitForEndTask.perform() }
            moc.automaticallyMergesChangesFromParent = true
            moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
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
    public func deleteValue<T: SimpleSerializedCoreDataStorable>(
        item: T
    ) -> Bool {
        return deleteAll() { (fetchRequest: NSFetchRequest<T.EntityType>) in
            item.setIdentifyingPredicate(fetchRequest: fetchRequest)
        }
    }
}
