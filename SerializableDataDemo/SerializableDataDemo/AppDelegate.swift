//
//  AppDelegate.swift
//  SerializableDataDemo
//
//  Created by Emily Ivie on 10/16/15.
//  Copyright © 2015 Emily Ivie. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        #if !TARGET_INTERFACE_BUILDER
        CoreDataManager.persistentContainer = persistentContainer
        #endif
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        UserDefaults.standard.synchronize()
        self.saveContext()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        UserDefaults.standard.synchronize()
        self.saveContext()
    }

    // MARK: - Core Data stack
    
    /// Warning: Keep in sync with currently selected migration. If they don't match, fatal error.
    private var migrationNames = [
        "SerializableDataDemo",
        "SerializableDataDemo2",
        "SerializableDataDemo3",
    ]
    
    private var storeName: String = "SerializableDataDemo"

    lazy var persistentContainer: NSPersistentContainer = {
        // Run migrations
        // (We have to do a few extra steps because I was dumb and misnamed sqlite before)
        let fileManager = FileManager.default
        if let oldStoreUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("SingleViewCoreData.sqlite"),
            let newStoreUrl = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("\(self.storeName).sqlite") {
            do {
                try self.migrateStoreToNewLocation(oldStoreUrl: oldStoreUrl, newStoreUrl: newStoreUrl)
                try Migrations(storeName: self.storeName, storeUrl: newStoreUrl).run(migrationNames: self.migrationNames)
            } catch {
                print(error)
            }
        }
        
        // Load up database stores
        let container = NSPersistentContainer(name: self.storeName)
        if let newStoreUrl = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("\(self.storeName).sqlite") {
            let description = NSPersistentStoreDescription(url: newStoreUrl)
            description.shouldMigrateStoreAutomatically = false
            description.shouldInferMappingModelAutomatically = false
            container.persistentStoreDescriptions = [description]
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("\(error)")
            }
        })
        return container
    }()
    
    private func migrateStoreToNewLocation(oldStoreUrl: URL, newStoreUrl: URL) throws {
        // fileExists does not work here :( - always returns false
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: oldStoreUrl.path) && !fileManager.fileExists(atPath: newStoreUrl.path) else { return }
        if let storeDirectory = Bundle.main.url(forResource: self.storeName, withExtension: "momd")?.lastPathComponent,
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

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

