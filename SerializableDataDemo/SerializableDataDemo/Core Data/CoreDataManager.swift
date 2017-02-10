//
//  CoreDataManager.swift
//  MEGameTracker
//
//  Created by Emily Ivie on 8/30/15.
//  Copyright © 2015 Emily Ivie. All rights reserved.
//

import UIKit
import CoreData

public typealias CoreDataManagerResultClosure = ((Bool)->Void)
public typealias SetAdditionColumnsClosure = ((NSManagedObject)->Void)
public typealias AlterFetchRequestClosure = ((NSFetchRequest<NSFetchRequestResult>)->Void)


/// An abstraction of basic CoreData functionality, applicable to all CoreDataStorable objects.
///
/// Example: 
///     CoreDataManager().save(myCoreDataStorableObject) { success in
///         print("I saved this object!")
///      }
public struct CoreDataManager {

    public static var persistentContainer: NSPersistentContainer?
    public static let SerializedDataKey = "serializedData"
    public var currentContext: NSManagedObjectContext?
    
    public init?(useMainContext: Bool = false) {
        guard CoreDataManager.persistentContainer != nil else { return nil }
        setContext(useMainContext: useMainContext)
    }
    
    mutating func setContext(useMainContext: Bool = false) {
        guard let container = CoreDataManager.persistentContainer else {
            print("Error: could not initalize core data container")
            return
        }
        currentContext = container.viewContext
    }

    /// Save a single row of a CoreDataStorable object.
    public func save<T: CoreDataStorable>(item: T) -> Bool {
        guard let moc = currentContext else { return false }
        var result: Bool = false
        moc.performAndWait() {
            guard let entity = NSEntityDescription.entity(forEntityName: T.coreDataEntityName, in: moc) else {
                print("Error: could not find core data entity \(T.coreDataEntityName)")
                return
            }
            
            let coreItem = self.fetchRow(item: item) ?? NSManagedObject(entity: entity, insertInto: moc)
            
            item.setColumnsOnSave(coreDataManager: self, coreItem: coreItem)
            
            do {
                try moc.save()
                result = true
            } catch let saveError as NSError {
                print("Error: save failed for \(T.coreDataEntityName): \(saveError)")
            }
        }
        
        return result
    }
    
    /// Retrieve single row with criteria closure.
    public func get<T: CoreDataStorable>(alterFetchRequest: AlterFetchRequestClosure = { _ in }) -> T? {
        if let coreItem = fetchRow(alterFetchRequest: alterFetchRequest, itemType: T.self),
            let serializedData = coreItem.value(forKey: CoreDataManager.SerializedDataKey) as? Data {
            return T(serializedData: serializedData)
        }
        return nil
    }
    
    /// Delete single row of a CoreDataStorable object.
    public func delete<T: CoreDataStorable>(item: T) -> Bool {
        guard let moc = currentContext else { return false }
        var result: Bool = false
        moc.performAndWait() { // if you want to async this, do it yourself
            do {
                if let coreItem = item.nsManagedObject(coreDataManager: self) {
                    moc.delete(coreItem)
                    try moc.save()
                    result = true
                }
            } catch let deleteError as NSError{
                print("Error: delete failed for \(T.coreDataEntityName): \(deleteError)")
            }
            
        }
        
        return result
    }

    /// Save multiple rows.
    public func saveAll<T: CoreDataStorable>(items: [T]) -> Bool {
        guard let moc = currentContext else { return false }
        var result: Bool = false
        moc.performAndWait() { // if you want to async this, do it yourself
            guard let entity = NSEntityDescription.entity(forEntityName: T.coreDataEntityName, in: moc) else {
                print("Error: could not find core data entity \(T.coreDataEntityName)")
                return
            }
            
            var loopResult = true
            for (index, item) in items.enumerated() {
            
                let coreItem = self.fetchRow(item: item) ?? NSManagedObject(entity: entity, insertInto: moc)
                
                item.setColumnsOnSave(coreDataManager: self, coreItem: coreItem)
                
                if index > 0 && index % 200 == 0 {
                    do {
                        try moc.save()
                        moc.reset()
                        print("Batch saved  \(T.coreDataEntityName) at \(index)")
                    } catch let saveError as NSError {
                        loopResult = false
                        print("Error: save failed for \(T.coreDataEntityName): \(saveError)")
                        break
                    }
                }
            }
            if loopResult {
                do {
                    try moc.save()
                    result = true
                } catch let saveError as NSError {
                    print("Error: save failed for \(T.coreDataEntityName): \(saveError)")
                }
            }
        }
        return result
    }
    
    /// Retrieve multiple rows with criteria closure.
    public func getAll<T: CoreDataStorable>(alterFetchRequest: @escaping AlterFetchRequestClosure) -> [T] {
        guard let moc = currentContext else { return [] }
        var result: [T] = []
        moc.performAndWait() { // if you want to async this, do it yourself
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: T.coreDataEntityName)
            alterFetchRequest(fetchRequest)
            do {
                let coreItems = (try moc.fetch(fetchRequest) as? [NSManagedObject]) ?? [NSManagedObject]()
                for coreItem in coreItems {
                    if let serializedData = coreItem.value(forKey: CoreDataManager.SerializedDataKey) as? Data,
                       let t = T(serializedData: serializedData) {
                        result.append(t)
                    }
                }
            } catch let fetchError as NSError {
                print("Error: getAll failed for \(T.coreDataEntityName): \(fetchError)")
            }
        }
        return result
    }
    
    /// Retrieve a count of matching entities
    public func getCount<T: CoreDataStorable>(alterFetchRequest: AlterFetchRequestClosure, itemType: T.Type) -> Int {
        guard let moc = currentContext else { return 0 }
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: T.coreDataEntityName)
        alterFetchRequest(fetchRequest)
        do {
            let count = try moc.count(for: fetchRequest)
            return count
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
            return 0
        }
    }
    
    /// Retrieve faulted data for optimization. This is our only call that needs an observer - all the others stop caring about database when they are done.
    /// see NSFetchedResultsController getItemAtIndexPath() for ease of retrieval thereafter.
    public func getAllFetchedResults<T: CoreDataStorable>(alterFetchRequest: AlterFetchRequestClosure, itemType: T.Type, sectionKey: String? = nil, cacheName: String? = nil) -> NSFetchedResultsController<NSFetchRequestResult>? {
        guard let moc = currentContext else { return nil }
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: T.coreDataEntityName)
        alterFetchRequest(fetchRequest)
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: sectionKey, cacheName: cacheName)
        
        do {
            try controller.performFetch()
            return controller
        } catch let fetchError as NSError {
            print("Error: getAll failed for \(T.coreDataEntityName): \(fetchError)")
        }
        
        return nil
    }

    /// Retrieve a single row of CoreData NSManagedObject matching a CoreDataStorable object.
    public func fetchRow<T: CoreDataStorable>(item: T) -> NSManagedObject? {
        return fetchRows(alterFetchRequest: { (fetchRequest: NSFetchRequest<NSFetchRequestResult>) in
            item.setIdentifyingPredicate(fetchRequest: fetchRequest)
        }, itemType: T.self, limitRows: 1).first
    }

    /// Retrieve a single row of CoreData NSManagedObject.
    public func fetchRow<T: CoreDataStorable>(alterFetchRequest: AlterFetchRequestClosure, itemType: T.Type) -> NSManagedObject? {
        return fetchRows(alterFetchRequest: alterFetchRequest, itemType: T.self, limitRows: 1).first
    }
    
    /// Retrieve multiple rows with criteria closure. Used for CoreData relationships only.
    public func fetchRows<T: CoreDataStorable>(alterFetchRequest: AlterFetchRequestClosure, likeItem: T, limitRows: Int? = nil) -> [NSManagedObject] {
        return fetchRows(alterFetchRequest: alterFetchRequest, itemType: T.self)
    }
    
    /// Retrieve multiple rows with criteria closure. Used for CoreData relationships only.
    public func fetchRows<T: CoreDataStorable>(alterFetchRequest: AlterFetchRequestClosure, itemType: T.Type, limitRows: Int? = nil) -> [NSManagedObject] {
        guard let moc = currentContext else { return [] }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: T.coreDataEntityName)
        if let limitRows = limitRows {
            fetchRequest.fetchLimit = limitRows
        }
        alterFetchRequest(fetchRequest)
        
        do {
            if let coreItems = try moc.fetch(fetchRequest) as? [NSManagedObject] {
                return coreItems
            } else {
                return []
            }
        } catch let fetchError as NSError {
            print("Error: fetchRows failed for \(T.coreDataEntityName): \(fetchError)")
        }
        
        return []
    }
    
    /// Remove all rows of a CoreData table.
    public func truncateTable<T: CoreDataStorable>(itemType: T.Type) -> Bool {
        return deleteAll(alterFetchRequest: { _ in }, itemType: itemType)
    }
    
    /// Remove all rows of a CoreData table.
    public func deleteAll<T: CoreDataStorable>(alterFetchRequest: @escaping AlterFetchRequestClosure, itemType: T.Type) -> Bool {
        guard let moc = currentContext else { return false }
        var result: Bool = false
        moc.performAndWait() { // if you want to async this, do it yourself
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: T.coreDataEntityName)
            alterFetchRequest(fetchRequest)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try _ = moc.execute(deleteRequest) as? NSBatchDeleteResult
                try moc.save()
                result = true
            } catch let deleteError as NSError {
                print("Error: delete failed for \(T.coreDataEntityName): \(deleteError)")
            }
        }
        return result
    }
}
