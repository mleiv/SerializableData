//
//  CoreDataManageable.swift
//
//  Copyright 2017 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.

import CoreData

public typealias AlterFetchRequestClosure = ((NSFetchRequest<NSManagedObject>)->Void)
public typealias SetAdditionColumnsClosure = ((NSManagedObject)->Void)

/// Manages the storage and retrieval of CoreDataStorable/SerializableData objects.
public protocol CoreDataManageable {

//MARK: Required:

    /// A static core data container for easy/efficient access.
    /// FYI, this is only created when asked for.
    static var current: CoreDataManager { get }
    /// Prevents any file saves - useful for testing.
    static var isConfineToMemoryStore: Bool { get }
    /// Prevents any automatic migrations - useful for heavy migrations.
    static var isManageMigrations: Bool { get }
    /// The store name of the current persistent store container.
    var storeName: String { get }
    /// The column name for the serializable data used for constructing serializable object.
    var serializedDataKey: String { get }
    /// This is managed for you - just declare it.
    var persistentContainer: NSPersistentContainer { get }
    /// Override the default context - useful when doing save/fetch in background.
    var specificContext: NSManagedObjectContext? { get }
    /// Implement this using the sample below, because protocols can't do this.
    init(storeName: String?, context: NSManagedObjectContext?)
    
//MARK: Already implemented:
    
    func runMigrations(storeUrl: URL)
    
// There's a bunch of other functions implemented below,
//    but right now I don't see a case for them being overridden, and I am lazy.
}

extension CoreDataManageable {
    
    public var context: NSManagedObjectContext { return specificContext ?? persistentContainer.viewContext }
    
    public init(storeName: String) {
        self.init(storeName: storeName, context: nil)
    }
    public init(context: NSManagedObjectContext?) {
        self.init(storeName: nil, context: context)
    }
//    // implement the following:
//    public init(storeName: String?, context: NSManagedObjectContext?) {
//        self.storeName = storeName ?? AppDelegate.coreDataStoreName
//        self.specificContext = context
//        if let storeName = storeName {
//            self.persistentContainer = NSPersistentContainer(name: storeName)
//            initContainer()
//        } else {
//            persistentContainer = CoreDataManager.current.persistentContainer
//        }
//    }
    
    /// Configure the persistent container.
    /// Also runs any manual migrations.
    public func initContainer() {
        let isConfineToMemoryStore = Self.isConfineToMemoryStore
        let isManageMigrations = Self.isManageMigrations
        
        // find our persistent store file
        guard let storeUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("\(storeName).sqlite") else {
            fatalError("Could not create path to \(storeName) sqlite")
        }
        
        // make any pending changes
        runMigrations(storeUrl: storeUrl)
        
        // Set some rules for this container
        let description = NSPersistentStoreDescription(url: storeUrl)
        if isManageMigrations {
            description.shouldMigrateStoreAutomatically = false
            description.shouldInferMappingModelAutomatically = false
        }
        if isConfineToMemoryStore {
            description.type = NSInMemoryStoreType
        }
        persistentContainer.persistentStoreDescriptions = [description]
        
        // load any existing stores
        persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            self.initContext()
        })
    }
    
    /// Configure the primary context.
    public func initContext() {
        print("Using persistent store: \(persistentContainer.persistentStoreCoordinator.persistentStores.first?.url)")
        let context = self.persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true // not triggered w/o autoreleasepool
        context.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
//        try? context.setQueryGenerationFrom(.current)
    }
    
    /// Runs any manual migrations before initializing the persistent container.
    /// If you are still using light migrations, leave this empty.
    public func runMigrations(storeUrl: URL) {}
    
    /// Save the primary context to file. Call this before exiting app.
    public func save() {
        let moc = persistentContainer.viewContext
        moc.performAndWait {
            do {
                print(moc.hasChanges)
                // save if changes found
                if moc.hasChanges {
                    try moc.save()
                }
            } catch {
                // this sucks, but not fatal IMO
                print("Unresolved error \(error)")
            }
        }
    }
    
    /// Retrieve single row with criteria closure.
    public func get<T: CoreDataStorable>(alterFetchRequest: @escaping AlterFetchRequestClosure = { _ in }) -> T? {
        let moc = context
        var result: T?
        moc.performAndWait { // performAndWait does not require autoreleasepool
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: T.coreDataEntityName)
            fetchRequest.fetchLimit = 1
            alterFetchRequest(fetchRequest)
            do {
                if let coreItem = try moc.fetch(fetchRequest).first,
                    let serializedData = coreItem.value(forKey: self.serializedDataKey) as? Data {
                    result = T(serializedData: serializedData)
                }
            } catch let fetchError as NSError {
                print("Error: get failed for \(T.coreDataEntityName): \(fetchError)")
            }
        }
        return result
    }
    
    /// Retrieve multiple rows with criteria closure.
    public func getAll<T: CoreDataStorable>(alterFetchRequest: @escaping AlterFetchRequestClosure) -> [T] {
        let moc = context
        var result: [T] = []
        moc.performAndWait { // performAndWait does not require autoreleasepool
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: T.coreDataEntityName)
            alterFetchRequest(fetchRequest)
            do {
                let coreItems = try moc.fetch(fetchRequest)
                for coreItem in coreItems {
                    if let serializedData = coreItem.value(forKey: self.serializedDataKey) as? Data,
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
    public func getCount<T: CoreDataStorable>(alterFetchRequest: @escaping AlterFetchRequestClosure, itemType: T.Type) -> Int {
        let moc = context
        var result = 0
        moc.performAndWait { // performAndWait does not require autoreleasepool
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: T.coreDataEntityName)
            alterFetchRequest(fetchRequest)
            do {
                result = try moc.count(for: fetchRequest)
            } catch let countError as NSError {
                print("Error: getCount failed for \(T.coreDataEntityName): \(countError)")
            }
        }
        return result
    }
    
    /// Retrieve faulted data for optimization. This is our only call that needs an observer - all the others stop caring about database when they are done.
    /// see NSFetchedResultsController getItemAtIndexPath() for ease of retrieval thereafter.
    public func getAllFetchedResults<T: CoreDataStorable>(alterFetchRequest: AlterFetchRequestClosure, itemType: T.Type, sectionKey: String? = nil, cacheName: String? = nil) -> NSFetchedResultsController<NSManagedObject>? {
        let moc = context
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: T.coreDataEntityName)
        alterFetchRequest(fetchRequest)
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: sectionKey, cacheName: cacheName)
        
        do {
            try controller.performFetch()
            return controller
        } catch let fetchError as NSError {
            print("Error: getAllFetchedResults failed for \(T.coreDataEntityName): \(fetchError)")
        }
        
        return nil
    }

    /// Retrieve a single row of CoreData NSManagedObject matching a CoreDataStorable object.
    public func fetchRow<T: CoreDataStorable>(item: T) -> NSManagedObject? {
        return fetchRows(alterFetchRequest: { (fetchRequest: NSFetchRequest<NSManagedObject>) in
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
        let moc = context
        var result: [NSManagedObject] = []
        
        do {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: T.coreDataEntityName)
            if let limitRows = limitRows {
                fetchRequest.fetchLimit = limitRows
            }
            alterFetchRequest(fetchRequest)
            
            result = try moc.fetch(fetchRequest)
        } catch let fetchError as NSError {
            print("Error: fetchRows failed for \(T.coreDataEntityName): \(fetchError)")
        }
        
        return result
    }

    /// Save a single row of a CoreDataStorable object.
    public func save<T: CoreDataStorable>(item: T) -> Bool {
        var result: Bool = false
        let waitForEndTask = DispatchWorkItem() {} // semaphore flag
        persistentContainer.performBackgroundTask { moc in
            defer { waitForEndTask.perform() }
            moc.automaticallyMergesChangesFromParent = true
            moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            autoreleasepool {
                let coreItem = Self(context: moc).fetchRow(item: item) ?? NSEntityDescription.insertNewObject(forEntityName: T.coreDataEntityName, into: moc)
                
                item.setColumnsOnSave(coreItem: coreItem)
            }
            do {
                try moc.save()
                result = true
            } catch let saveError as NSError {
                print("Error: save failed for \(T.coreDataEntityName): \(saveError)")
            }
        }
        waitForEndTask.wait()
        return result
    }

    /// Save multiple rows.
    public func saveAll<T: CoreDataStorable>(items: [T]) -> Bool {
        guard !items.isEmpty else { return true }
        var result: Bool = false
        let waitForEndTask = DispatchWorkItem() {} // semaphore flag
        persistentContainer.performBackgroundTask { moc in
            defer { waitForEndTask.perform() }
            moc.automaticallyMergesChangesFromParent = true
            moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            autoreleasepool {
                for item in items {
                    let coreItem = Self(context: moc).fetchRow(item: item) ?? NSEntityDescription.insertNewObject(forEntityName: T.coreDataEntityName, into: moc)
                    
                    item.setColumnsOnSave(coreItem: coreItem)
                }
            }
            do {
                try moc.save()
                result = true
            } catch let saveError as NSError {
                print("Error: save failed for \(T.coreDataEntityName): \(saveError)")
            }
        }
        waitForEndTask.wait()
        return result
    }
    
    /// Delete single row of a CoreDataStorable object.
    public func delete<T: CoreDataStorable>(item: T) -> Bool {
        var result: Bool = false
        let waitForEndTask = DispatchWorkItem() {} // semaphore flag
        persistentContainer.performBackgroundTask { moc in
            defer { waitForEndTask.perform() }
            moc.automaticallyMergesChangesFromParent = true
            moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            autoreleasepool {
                if let coreItem = item.nsManagedObject(context: moc) {
                    moc.delete(coreItem)
                }
            }
            do {
                try moc.save()
                result = true
            } catch let deleteError as NSError{
                print("Error: delete failed for \(T.coreDataEntityName): \(deleteError)")
            }
        }
        waitForEndTask.wait()
        return result
    }
    
    /// Remove all rows of a CoreData table.
    public func truncateTable<T: CoreDataStorable>(itemType: T.Type) -> Bool {
        return deleteAll(alterFetchRequest: { _ in }, itemType: itemType)
    }
    
    /// Remove all rows of a CoreData table.
    public func deleteAll<T: CoreDataStorable>(
        alterFetchRequest: @escaping AlterFetchRequestClosure,
        itemType: T.Type
    ) -> Bool {
        var result: Bool = false
        let waitForEndTask = DispatchWorkItem() {} // semaphore flag
        persistentContainer.performBackgroundTask { moc in
            defer { waitForEndTask.perform() }
            moc.automaticallyMergesChangesFromParent = true
            moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: T.coreDataEntityName)
            alterFetchRequest(fetchRequest)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
            
            do {
                try _ = moc.execute(deleteRequest) as? NSBatchDeleteResult
                try moc.save()
                result = true
            } catch let deleteError as NSError {
                print("Error: deleteAll failed for \(T.coreDataEntityName): \(deleteError)")
            }
        }
        waitForEndTask.wait()
        return result
    }
}
