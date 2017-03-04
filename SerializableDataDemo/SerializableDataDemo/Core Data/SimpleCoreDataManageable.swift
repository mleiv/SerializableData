//
//  SimpleCoreDataManageable.swift
//
//  Copyright 2017 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.


import CoreData

/// Manages the storage and retrieval of CoreDataStorable/SerializableData objects.
public protocol SimpleCoreDataManageable {

//MARK: Required:

    /// Prevents any automatic migrations - useful for heavy migrations.
    static var isManageMigrations: Bool { get }
    /// A flag for the type of store.
    var isConfinedToMemoryStore: Bool { get }
    /// The store name of the current persistent store container.
    var storeName: String { get }
    /// This is managed for you - just declare it.
    var persistentContainer: NSPersistentContainer { get }
    /// Override the default context - useful when doing save/fetch in background.
    var specificContext: NSManagedObjectContext? { get }
    /// Implement this using the sample below, because protocols can't do this.
    init(storeName: String?, context: NSManagedObjectContext?, isConfineToMemoryStore: Bool)
    
//MARK: Already implemented:
    
    func runMigrations(storeUrl: URL)
    
    /// Save the primary context to file. Call this before exiting App.current.
    func save()
    
    /// Retrieve single row with criteria closure.
    func getOne<T: NSManagedObject>(
        alterFetchRequest: @escaping AlterFetchRequest<T>
    ) -> T?
    
    /// Retrieve multiple rows with criteria closure.
    func getAll<T: NSManagedObject>(
        alterFetchRequest: @escaping AlterFetchRequest<T>
    ) -> [T]
    
    /// Retrieve a count of matching entities
    func getCount<T: NSManagedObject>(
        alterFetchRequest: @escaping AlterFetchRequest<T>
    ) -> Int
    
    /// Retrieve faulted data for optimization.
    func getAllFetchedResults<T: NSManagedObject>(
        alterFetchRequest: AlterFetchRequest<T>,
        sectionKey: String?,
        cacheName: String?
    ) -> NSFetchedResultsController<T>?
    
    /// Creates a new row of CoreData and returns a SimpleCoreDataStorable object.
    func createOne<T: NSManagedObject>(
        setInitialValues: @escaping SetAdditionalColumns<T>
    ) -> T?

    /// Save a single row of an entity.
    func saveChanges<T: NSManagedObject>(
        item: T,
        setChangedValues: @escaping SetAdditionalColumns<T>
    ) -> Bool
    
    /// Delete single row of a entity.
    func deleteOne<T: NSManagedObject>(
        item: T
    ) -> Bool
    
    /// Remove all rows of an entity matching restrictions.
    func deleteAll<T: NSManagedObject>(
        alterFetchRequest: @escaping AlterFetchRequest<T>
    ) -> Bool
    
}

// MARK: Core data initialization functions
extension SimpleCoreDataManageable {

    static var isCoreDataInaccessible: Bool {
        #if TARGET_INTERFACE_BUILDER
            return true
        #else
            return false
        #endif
    }
    
    public var context: NSManagedObjectContext { return specificContext ?? persistentContainer.viewContext }
    
    public init(storeName: String, isConfineToMemoryStore: Bool = false) {
        self.init(storeName: storeName, context: nil, isConfineToMemoryStore: isConfineToMemoryStore)
    }
    public init(context: NSManagedObjectContext?) {
        self.init(storeName: nil, context: context, isConfineToMemoryStore: false)
    }
    
//    // implement the following:
//    public init(storeName: String?, context: NSManagedObjectContext?, isConfineToMemoryStore: Bool) {
//        self.storeName = storeName ?? AppDelegate.coreDataStoreName
//        self.specificContext = context
//        if let storeName = storeName {
//            self.persistentContainer = NSPersistentContainer(name: storeName)
//            initContainer(isConfineToMemoryStore: isConfineToMemoryStore)
//        } else {
//            persistentContainer = CoreDataManager.current.persistentContainer
//        }
//    }
    
    /// Configure the persistent container.
    /// Also runs any manual migrations.
    public func initContainer(isConfineToMemoryStore: Bool = false) {
    
        guard !Self.isCoreDataInaccessible else { return }
        
        let isManageMigrations = Self.isManageMigrations
        
        // find our persistent store file
        guard let storeUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("\(storeName).sqlite") else {
            fatalError("Could not create path to \(storeName) sqlite")
        }
        
        // make any pending changes
        if !isConfineToMemoryStore {
            runMigrations(storeUrl: storeUrl)
        }
        
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
    
}

// MARK: Core data content functions
extension SimpleCoreDataManageable {
    /// The closure type for editing fetch requests.
    public typealias AlterFetchRequest<T: NSManagedObject> = ((NSFetchRequest<T>)->Void)
    
    /// The closure type for editing fetched entity objects.
    public typealias SetAdditionalColumns<T: NSManagedObject> = ((T)->Void)
    
    public typealias TransformEntity<T: NSManagedObject, U> = ((T)->U?)
    
    /// Save the primary context to file. Call this before exiting App.current.
    public func save() {
        guard !Self.isCoreDataInaccessible else { return }
        let moc = persistentContainer.viewContext
        moc.performAndWait {
            do {
                // save if changes found
                if moc.hasChanges {
                    try moc.save()
                }
            } catch {
                // this sucks, but not fatal IMO
                print("Failed to save context: \(error)")
            }
        }
    }
    
    /// Retrieve single row with criteria closure.
    public func getOne<T: NSManagedObject>(
        alterFetchRequest: @escaping AlterFetchRequest<T>
    ) -> T? {
        guard !Self.isCoreDataInaccessible else { return nil }
        let moc = context
        var result: T?
        moc.performAndWait {
            guard let fetchRequest = T.fetchRequest() as? NSFetchRequest<T> else { return }
            alterFetchRequest(fetchRequest)
            fetchRequest.fetchLimit = 1
            autoreleasepool {
                do {
                    if let item = try fetchRequest.execute().first {
                        result = item
                    }
                } catch let fetchError as NSError {
                    print("Error: get failed for \(T.self): \(fetchError)")
                }
            }
        }
        return result
    }
    
    /// Retrieve multiple rows with criteria closure, and transform them to another data type.
    public func getOneTransformed<T: NSManagedObject, U>(
        transformEntity: @escaping TransformEntity<T,U>,
        alterFetchRequest: @escaping AlterFetchRequest<T>
    ) -> U? {
        guard !Self.isCoreDataInaccessible else { return nil }
        let moc = context
        var result: U?
        moc.performAndWait {
            guard let fetchRequest = T.fetchRequest() as? NSFetchRequest<T> else { return }
            alterFetchRequest(fetchRequest)
            fetchRequest.fetchLimit = 1
            autoreleasepool {
                do {
                    if let item = try fetchRequest.execute().first {
                        result = transformEntity(item)
                    }
                } catch let fetchError as NSError {
                    print("Error: get failed for \(T.self): \(fetchError)")
                }
            }
        }
        return result
    }
    
    /// Retrieve multiple rows with criteria closure.
    public func getAll<T: NSManagedObject>(
        alterFetchRequest: @escaping AlterFetchRequest<T>
    ) -> [T] {
        guard !Self.isCoreDataInaccessible else { return [] }
        let moc = context
        var result: [T] = []
        moc.performAndWait { // performAndWait does not require autoreleasepool
            guard let fetchRequest = T.fetchRequest() as? NSFetchRequest<T> else { return }
            alterFetchRequest(fetchRequest)
            do {
                result = try fetchRequest.execute()
            } catch let fetchError as NSError {
                print("Error: getAll failed: \(fetchError)")
            }
        }
        return result
    }
    
    /// Retrieve multiple rows with criteria closure, and transform them to another data type.
    ///
    /// WARNING: Do not perform any core data action in transformEntity.
    ///   Just retrieve your values and do stuff with them later, or it will deadlock!
    public func getAllTransformed<T: NSManagedObject, U>(
        transformEntity: @escaping TransformEntity<T,U>,
        alterFetchRequest: @escaping AlterFetchRequest<T>
    ) -> [U] {
        guard !Self.isCoreDataInaccessible else { return [] }
        let moc = context
        var result: [U] = []
        moc.performAndWait { // performAndWait does not require autoreleasepool
            guard let fetchRequest = T.fetchRequest() as? NSFetchRequest<T> else { return }
            alterFetchRequest(fetchRequest)
            do {
                let items: [T] = try fetchRequest.execute()
                result = items.flatMap { transformEntity($0) }
            } catch let fetchError as NSError {
                print("Error: getAllTransformed failed: \(fetchError)")
            }
        }
        return result
    }
    
    /// Retrieve a count of matching entities
    public func getCount<T: NSManagedObject>(
        alterFetchRequest: @escaping AlterFetchRequest<T>
    ) -> Int {
        guard !Self.isCoreDataInaccessible else { return 0 }
        let moc = context
        var result = 0
        moc.performAndWait { // performAndWait does not require autoreleasepool
            guard let fetchRequest = T.fetchRequest() as? NSFetchRequest<T> else { return }
            alterFetchRequest(fetchRequest)
            do {
                result = try moc.count(for: fetchRequest)
            } catch let countError as NSError {
                print("Error: getCount failed for \(T.self): \(countError)")
            }
        }
        return result
    }
    
    /// Retrieve faulted data for optimization.
    public func getAllFetchedResults<T: NSManagedObject>(
        alterFetchRequest: AlterFetchRequest<T>,
        sectionKey: String?,
        cacheName: String?
    ) -> NSFetchedResultsController<T>? {
        guard !Self.isCoreDataInaccessible else { return nil }
        let moc = context
        guard let fetchRequest = T.fetchRequest() as? NSFetchRequest<T> else { return nil }
        alterFetchRequest(fetchRequest)
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: sectionKey, cacheName: cacheName)
        
        do {
            try controller.performFetch()
            return controller
        } catch let fetchError as NSError {
            print("Error: getAllFetchedResults failed for \(T.self): \(fetchError)")
        }
        
        return nil
    }
    
    /// Creates a new row of CoreData and returns a SimpleCoreDataStorable object.
    public func createOne<T: NSManagedObject>(
        setInitialValues: @escaping SetAdditionalColumns<T>
    ) -> T? {
        guard !Self.isCoreDataInaccessible else { return nil }
        let moc = context
        var result: T?
        let waitForEndTask = DispatchWorkItem() {} // semaphore flag
        persistentContainer.performBackgroundTask { moc in
            defer { waitForEndTask.perform() }
            moc.automaticallyMergesChangesFromParent = true
            moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            
            autoreleasepool {
                let coreItem = T(context: moc)
                setInitialValues(coreItem)
                result = coreItem
            }
            
            do {
                try moc.save()
            } catch let createError as NSError {
                print("Error: create failed for \(T.self): \(createError)")
                result = nil
            }
        }
        waitForEndTask.wait()
        if let result = result {
            return moc.object(with: result.objectID) as? T
        }
        return nil
    }

    /// Save a single row of an entity.
    public func saveChanges<T: NSManagedObject>(
        item: T,
        setChangedValues: @escaping SetAdditionalColumns<T>
    ) -> Bool {
        guard !Self.isCoreDataInaccessible else { return false }
        var result: Bool = false
        let waitForEndTask = DispatchWorkItem() {} // semaphore flag
        persistentContainer.performBackgroundTask { moc in
            defer { waitForEndTask.perform() }
            moc.automaticallyMergesChangesFromParent = true
            moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            
            autoreleasepool {
                if let coreItem = moc.object(with: item.objectID) as? T {
                    // CAUTION: anything you do here *must* use the same context, 
                    // so if you are setting up relationships, create a new SimpleCoreDataManager 
                    // and use that to do any fetching/saving:
                    //
                    //     let localManager = SimpleCoreDataManager(context: coreItem.managedObjectContext)
                    //     coreItem.otherEntity = OtherEntity.get(with: localManager) {
                    //         fetchRequest.predicate = NSPredicate(format: "(%K == %@)", #keyPath(OtherEntity.id), lookupId)
                    //     }
                    setChangedValues(coreItem)
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
    
    /// Delete single row of a entity.
    public func deleteOne<T: NSManagedObject>(
        item: T
    ) -> Bool {
        return deleteAll() { (fetchRequest: NSFetchRequest<T>) in
            fetchRequest.predicate = NSPredicate(format: "(%K == %@)", #keyPath(NSManagedObject.objectID), item.objectID)
        }
    }
    
    /// Remove all rows of an entity matching restrictions.
    public func deleteAll<T: NSManagedObject>(
        alterFetchRequest: @escaping AlterFetchRequest<T>
    ) -> Bool {
        guard !Self.isCoreDataInaccessible else { return false }
        guard persistentContainer.persistentStoreDescriptions.first?.type != NSInMemoryStoreType else {
            return tediousManualDelete(alterFetchRequest: alterFetchRequest)
        }
        var result: Bool = false
        let waitForEndTask = DispatchWorkItem() {} // semaphore flag
        persistentContainer.performBackgroundTask { moc in
            defer { waitForEndTask.perform() }
            moc.automaticallyMergesChangesFromParent = true
            moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            
            guard let fetchRequest = T.fetchRequest() as? NSFetchRequest<T> else { return }
            alterFetchRequest(fetchRequest)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
            
            do {
                try _ = moc.execute(deleteRequest) as? NSBatchDeleteResult
                try moc.save()
                result = true
            } catch let deleteError as NSError {
                print("Error: deleteAll failed for \(T.self): \(deleteError)")
            }
        }
        waitForEndTask.wait()
        return result
    }
    
    private func tediousManualDelete<T: NSManagedObject>(
        alterFetchRequest: @escaping AlterFetchRequest<T>
    ) -> Bool {
        var result: Bool = false
        let waitForEndTask = DispatchWorkItem() {} // semaphore flag
        persistentContainer.performBackgroundTask { moc in
            defer { waitForEndTask.perform() }
            moc.automaticallyMergesChangesFromParent = true
            moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            
            guard let fetchRequest = T.fetchRequest() as? NSFetchRequest<T> else { return }
            fetchRequest.includesPropertyValues = false
            alterFetchRequest(fetchRequest)
            
            autoreleasepool {
                do {
                    for item in try fetchRequest.execute() {
                        moc.delete(item)
                    }
                } catch let deleteError as NSError {
                    print("Error: delete row failed for \(T.self): \(deleteError)")
                }
            }
            
            do {
                try moc.save()
                result = true
            } catch let deleteError as NSError {
                print("Error: deleteAll failed for \(T.self): \(deleteError)")
            }
        }
        waitForEndTask.wait()
        return result
    }
}
