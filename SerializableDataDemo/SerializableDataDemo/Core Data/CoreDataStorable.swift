//
//  CoreDataStorable.swift
//
//  Copyright 2017 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.

import CoreData

/// A protocol for describing classes or structs that can be stored in core data using the CoreDataManager
public protocol CoreDataStorable: SerializedDataStorable, SerializedDataRetrievable {

    /// Define in the object itself. 
    /// Should be the name of the CoreData table.
    static var coreDataEntityName: String { get }
    
    /// Defined for you by the protocol.
    /// Returns the CoreData row that is equal to this object
    func nsManagedObject(context: NSManagedObjectContext?) -> NSManagedObject?
    
    /// Define in the object itself. 
    /// Alters the predicate to retrieve only the row equal to this object
    func setIdentifyingPredicate(fetchRequest: NSFetchRequest<NSManagedObject>)
    
    /// Define in the object itself. 
    /// Alters the object to store additional columns (serialized data stored by default).
    /// Useful to add searchable columns like name or id.
    ///
    /// Note: coreItem.managedObjectContext reports incorrect moc when using performBackgroundTask.
    func setAdditionalColumnsOnSave(
        coreItem: NSManagedObject
    )
    
    /// Defined for you by the protocol. Recommended to leave unchanged.
    func setColumnsOnSave(
        coreItem: NSManagedObject
    )
    
    /// Defined for you by the protocol. Okay to customize (leave preSave() call).
    mutating func save(coreDataManager: CoreDataManager?) -> Bool
    
    /// Defined for you by the protocol. Okay to customize.
    mutating func delete(coreDataManager: CoreDataManager?) -> Bool
    
    /// Defined for you by the protocol. Okay to customize.
    static func deleteAll(
        coreDataManager: CoreDataManager?,
        alterFetchRequest: @escaping AlterFetchRequestClosure
    ) -> Bool
    
    /// Defined for you by the protocol. Recommended to leave unchanged.
    func truncateTable()
}
extension CoreDataStorable {

    public func nsManagedObject(context: NSManagedObjectContext?) -> NSManagedObject? {
        return CoreDataManager(context: context).fetchRow(item: self)
    }
    
    public func setColumnsOnSave(
        coreItem: NSManagedObject
    ) {
        coreItem.setValue(self.serializedData, forKey: CoreDataManager.current.serializedDataKey)
        setAdditionalColumnsOnSave(coreItem: coreItem)
    }
    
    public mutating func save() -> Bool {
        return save(coreDataManager: nil)
    }
    public mutating func save(coreDataManager: CoreDataManager?) -> Bool {
        let isSaved = (coreDataManager ?? CoreDataManager.current)?.save(item: self) ?? false
        return isSaved
    }
    
    public mutating func delete() -> Bool {
        return delete(coreDataManager: nil)
    }
    public mutating func delete(coreDataManager: CoreDataManager?) -> Bool {
        let isDeleted = (coreDataManager ?? CoreDataManager.current)?.delete(item: self) ?? false
        return isDeleted
    }
    
    public static func deleteAll(
        alterFetchRequest: @escaping AlterFetchRequestClosure
    ) -> Bool {
        return deleteAll(coreDataManager: nil, alterFetchRequest: alterFetchRequest)
    }
    public static func deleteAll(
        coreDataManager: CoreDataManager?,
        alterFetchRequest: @escaping AlterFetchRequestClosure
    ) -> Bool {
        let manager = coreDataManager ?? CoreDataManager.current
        return manager.deleteAll(alterFetchRequest: alterFetchRequest, itemType: Self.self) 
    }
    
    public func truncateTable() {
        _ = CoreDataManager.current.truncateTable(itemType: Self.self)
    }
}

/// Some additional utilities for CoreDataStorable.
/// Unfortunately, they make it impossible to use CoreDataStorable as a parameter, so rather than use type erasure (which requires me to specify type every time I call one of these functions), I creating an additional protocol.
public protocol CoreDataStorableExtra: CoreDataStorable {

    /// Define in the object itself. 
    /// Should be the name of the CoreData table.
    associatedtype CoreDataEntityType: NSManagedObject

    /// Defined for you by the protocol. Okay to customize.
    static func saveAll(
        items: [Self],
        coreDataManager: CoreDataManager?
    ) -> Bool
    /// Defined for you by the protocol. Okay to customize.
    static func get(
        coreDataManager: CoreDataManager?,
        alterFetchRequest: @escaping AlterFetchRequestClosure
    ) -> Self?
    /// Defined for you by the protocol. Okay to customize.
    static func getAll(
        coreDataManager: CoreDataManager?,
        alterFetchRequest: @escaping AlterFetchRequestClosure
    ) -> [Self]
}

// default implementations for the protocol:
extension CoreDataStorableExtra {
    
    public static func saveAll(
        items: [Self]
    ) -> Bool {
        return saveAll(items: items, coreDataManager: nil)
    }
    public static func saveAll(
        items: [Self],
        coreDataManager: CoreDataManager?
    ) -> Bool {
        guard !items.isEmpty else { return true }
        let manager = coreDataManager ?? CoreDataManager.current
        let isSaved = manager.saveAll(items: items) 
        return isSaved
    }
    
    public static func get(
        alterFetchRequest: @escaping AlterFetchRequestClosure = { _ in }
    ) -> Self? {
        return get(coreDataManager: nil, alterFetchRequest: alterFetchRequest)
    }
    public static func get(
        coreDataManager: CoreDataManager?,
        alterFetchRequest: @escaping AlterFetchRequestClosure
    ) -> Self? {
        return _get(coreDataManager: coreDataManager, alterFetchRequest: alterFetchRequest)
    }
    
    internal static func _get(
        coreDataManager: CoreDataManager? = nil,
        alterFetchRequest: @escaping AlterFetchRequestClosure
    ) -> Self? {
        let manager = coreDataManager ?? CoreDataManager.current
        let one: Self? = manager.get(alterFetchRequest: alterFetchRequest)
        return one
    }
    
    public static func getAll(
        alterFetchRequest: @escaping AlterFetchRequestClosure = { _ in }
    ) -> [Self] {
        return getAll(coreDataManager: nil, alterFetchRequest: alterFetchRequest)
    }
    public static func getAll(
        coreDataManager: CoreDataManager?,
        alterFetchRequest: @escaping AlterFetchRequestClosure
    ) -> [Self] {
        return _getAll(coreDataManager: coreDataManager, alterFetchRequest: alterFetchRequest)
    }
    internal static func _getAll(
        coreDataManager: CoreDataManager? = nil,
        alterFetchRequest: @escaping AlterFetchRequestClosure
    ) -> [Self] {
        let manager = coreDataManager ?? CoreDataManager.current
        let all: [Self] = manager.getAll(alterFetchRequest: alterFetchRequest) 
        return all
    }
}
