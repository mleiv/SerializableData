//
//  CoreDataManager.swift (Abbreviated version for example only)
//
//  Copyright 2015 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.
//


import UIKit
import CoreData

public enum CoreDataManagerError : Error {
    case notFound
    case failedToInitializedObject
}

public struct CoreDataManager {

    public static var context: NSManagedObjectContext?
    
    internal struct Keys {
        static let serializedData = "serializedData"
    }

    /// save a single row
    public static func save<T: CoreDataStorable>(_ item: T) -> Bool {
        guard let context = self.context else {
            print("Error: could not initalize core data context")
            return false
        }
        guard let entity = NSEntityDescription.entity(forEntityName: T.coreDataEntityName, in: context) else {
            print("Error: could not find core data entity \(T.coreDataEntityName)")
            return false
        }
        
        let coreItem = fetchRow(item) ?? NSManagedObject(entity: entity, insertInto: context)

        coreItem.setValue(item.getData().serializedString, forKey: Keys.serializedData)
        
        item.setAdditionalColumns(coreItem)
        
        do {
            try context.save()
            return true
        } catch let saveError as NSError {
            print("save failed for \(T.coreDataEntityName): \(saveError.localizedDescription)")
        }
        
        return false
    }
    
    
    /// delete single row with item passed
    public static func delete<T: CoreDataStorable>(_ item: T) -> Bool {
        guard let context = self.context else {
            print("Error: could not initalize core data context")
            return false
        }
        
        do {
            if let coreItem = item.nsManagedObject {
                context.delete(coreItem)
                try context.save()
                return true
            }
        } catch let deleteError as NSError{
            print("delete failed for \(T.coreDataEntityName): \(deleteError.localizedDescription)")
        }
        
        return false
    }
    
    /// get a single row
    /// (I have a much better way of doing this with predicates, but it is long and requires lots of additional protocols, so again, EXAMPLE ONLY, lol)
    public static func get<T: CoreDataStorable>(_ item: T) -> T? {
        do {
            if let coreItem = fetchRow(item) {
                let serializedString = (coreItem.value(forKey: Keys.serializedData) as? String) ?? ""
                if let t = T(serializedString: serializedString) {
                    return t
                } else {
                    throw CoreDataManagerError.failedToInitializedObject
                }
            }
        } catch let fetchError as NSError {
            print("get failed for \(T.coreDataEntityName): \(fetchError.localizedDescription)")
        }
        return nil
    }
    
    
    /// retrieve multiple rows
    public static func getAll<T: CoreDataStorable>() -> [T] {
        guard let context = self.context else {
            print("Error: could not initalize core data context")
            return []
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: T.coreDataEntityName)
        
        do {
            let coreItems = (try context.fetch(fetchRequest) as? [NSManagedObject]) ?? [NSManagedObject]()
            let results: [T] = try coreItems.map { (coreItem) in
                let serializedString = (coreItem.value(forKey: Keys.serializedData) as? String) ?? ""
                if let t = T(serializedString: serializedString) {
                    return t
                } else {
                    throw CoreDataManagerError.failedToInitializedObject
                }
            }
            return results
        } catch let fetchError as NSError {
            print("getAll failed for \(T.coreDataEntityName): \(fetchError.localizedDescription)")
        }
        
        return []
    }

    /// retrieve single row introspective core data
    public static func fetchRow<T: CoreDataStorable>(_ item: T) -> NSManagedObject? {
        guard let context = self.context else {
            print("Error: could not initalize core data context")
            return nil
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: T.coreDataEntityName)
        fetchRequest.fetchLimit = 1
        item.setIdentifyingPredicate(fetchRequest)
        
        do {
            let coreItems = (try context.fetch(fetchRequest) as? [NSManagedObject]) ?? [NSManagedObject]()
            return coreItems.first
        } catch let fetchError as NSError {
            print("fetchRow failed for \(T.coreDataEntityName): \(fetchError.localizedDescription)")
        }
        return nil
    }
    
}
