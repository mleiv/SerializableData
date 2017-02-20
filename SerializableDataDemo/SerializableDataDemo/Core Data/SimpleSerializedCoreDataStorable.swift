//
//  CoreDataStorable.swift
//
//  Copyright 2017 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.

import CoreData

public protocol SimpleSerializedCoreDataStorable: SerializedDataStorable, SerializedDataRetrievable {

// MARK: Required

    /// Type of the core data entity.
    associatedtype EntityType: NSManagedObject
    
    /// Alters the predicate to retrieve only the row equal to this object.
    func setIdentifyingPredicate(
        fetchRequest: NSFetchRequest<EntityType>
    )
    
    /// Sets core data values to match struct values (specific).
    func setAdditionalColumnsOnSave(
        coreItem: EntityType
    )
    
// MARK: Optional
    
    /// A reference to the current core data manager.
    static var defaultManager: SimpleSerializedCoreDataManageable { get }

    /// Returns the CoreData row that is equal to this object.
    func entity(context: NSManagedObjectContext?) -> EntityType?
    
    /// Sets core data values to match struct values (general).
    ///
    /// DON'T OVERRIDE.
    func setColumnsOnSave(
        coreItem: EntityType
    )
    
    /// Gets the struct to match the core data request.
    static func get(
        with manager: SimpleSerializedCoreDataManageable?,
        alterFetchRequest: @escaping AlterFetchRequestClosure<EntityType>
    ) -> Self?
    
    /// Gets all structs that match the core data request.
    static func getAll(
        with manager: SimpleSerializedCoreDataManageable?,
        alterFetchRequest: @escaping AlterFetchRequestClosure<EntityType>
    ) -> [Self]
    
    /// Saves the struct to core data.
    mutating func save(
        with manager: SimpleSerializedCoreDataManageable?
    ) -> Bool
    
    /// Saves all the structs to core data.
    static func saveAll(
        items: [Self],
        with manager: SimpleSerializedCoreDataManageable?
    ) -> Bool
    
    /// Deletes the struct's core data equivalent.
    mutating func delete(
        with manager: SimpleSerializedCoreDataManageable?
    ) -> Bool
    
    /// Deletes all rows that match the core data request.
    static func deleteAll(
        with manager: SimpleSerializedCoreDataManageable?,
        alterFetchRequest: @escaping AlterFetchRequestClosure<EntityType>
    ) -> Bool
}

extension SimpleSerializedCoreDataStorable {
    
    /// Convenience - get the static version for easy instance reference.
    public var defaultManager: SimpleSerializedCoreDataManageable {
        return Self.defaultManager
    }
    
    /// Protocol conformance.
    /// Returns the CoreData row that is equal to this object.
    public func entity(context: NSManagedObjectContext?) -> EntityType? {
        let manager = type(of: defaultManager).init(context: context)
        return manager.getObject(item: self)
    }
    
    /// Sets core data values to match struct values (general).
    ///
    /// DON'T OVERRIDE.
    public func setColumnsOnSave(
        coreItem: EntityType
    ) {
        coreItem.setValue(self.serializedData, forKey: defaultManager.serializedDataKey)
        setAdditionalColumnsOnSave(coreItem: coreItem)
    }
    
    /// Protocol conformance.
    /// Gets the struct to match the core data request.
    public static func get(
        with manager: SimpleSerializedCoreDataManageable?,
        alterFetchRequest: @escaping AlterFetchRequestClosure<EntityType>
    ) -> Self? {
        return _get(with: manager, alterFetchRequest: alterFetchRequest)
    }
    
    /// Convenience version of get:manager:alterFetchRequest (manager not required).
    public static func get(
        alterFetchRequest: @escaping AlterFetchRequestClosure<EntityType>
    ) -> Self? {
        return get(with: nil, alterFetchRequest: alterFetchRequest)
    }
    
    /// Convenience version of get:manager:alterFetchRequest (no parameters required).
    public static func get() -> Self? {
        return get(with: nil) { (fetchRequest: NSFetchRequest<EntityType>) in }
    }
    
    /// Root version of get:manager:alterFetchRequest (you can still call this if you override that).
    ///
    /// DO NOT OVERRIDE.
    internal static func _get(
        with manager: SimpleSerializedCoreDataManageable?,
        alterFetchRequest: @escaping AlterFetchRequestClosure<EntityType>
    ) -> Self? {
        let manager = manager ?? defaultManager
        let one: Self? = manager.getValue(alterFetchRequest: alterFetchRequest)
        return one
    }
    
    /// Protocol conformance.
    /// Gets all structs that match the core data request.
    public static func getAll(
        with manager: SimpleSerializedCoreDataManageable?,
        alterFetchRequest: @escaping AlterFetchRequestClosure<EntityType>
    ) -> [Self] {
        return _getAll(with: manager, alterFetchRequest: alterFetchRequest)
    }
    
    /// Convenience version of getAll:manager:alterFetchRequest (manager not required).
    public static func getAll(
        alterFetchRequest: @escaping AlterFetchRequestClosure<EntityType>
    ) -> [Self] {
        return getAll(with: nil, alterFetchRequest: alterFetchRequest)
    }
    
    /// Convenience version of getAll:manager:alterFetchRequest (no parameters required).
    public static func getAll() -> [Self] {
        return getAll(with: nil) { _ in }
    }
    
    /// Root version of getAll:manager:alterFetchRequest (you can still call this if you override that).
    ///
    /// DO NOT OVERRIDE.
    internal static func _getAll(
        with manager: SimpleSerializedCoreDataManageable?,
        alterFetchRequest: @escaping AlterFetchRequestClosure<EntityType>
    ) -> [Self] {
        let manager = manager ?? defaultManager
        let all: [Self] = manager.getAllValues(alterFetchRequest: alterFetchRequest)
        return all
    }

    /// Protocol conformance.
    /// Saves the struct to core data.
    public mutating func save(
        with manager: SimpleSerializedCoreDataManageable?
    ) -> Bool {
        let manager = manager ?? defaultManager
        let isSaved = manager.saveValue(item: self)
        return isSaved
    }
    
    /// Convenience version of save:manager (no parameters required).
    public mutating func save() -> Bool {
        return save(with: nil)
    }
    
    /// Protocol conformance.
    /// Saves all the structs to core data.
    public static func saveAll(
        items: [Self],
        with manager: SimpleSerializedCoreDataManageable?
    ) -> Bool {
        guard !items.isEmpty else { return true }
        let manager = manager ?? defaultManager
        let isSaved = manager.saveAllValues(items: items)
        return isSaved
    }
    
    /// Convenience version of saveAll:items:manager (manager not required).
    public static func saveAll(
        items: [Self]
    ) -> Bool {
        return saveAll(items: items, with: nil)
    }
    
    /// Protocol conformance.
    /// Deletes the struct's core data equivalent.
    public mutating func delete(
        with manager: SimpleSerializedCoreDataManageable?
    ) -> Bool {
        let manager = manager ?? defaultManager
        let isDeleted = manager.deleteValue(item: self)
        return isDeleted
    }
    
    /// Convenience version of delete:manager (no parameters required).
    public mutating func delete() -> Bool {
        return delete(with: nil)
    }
    
    /// Protocol conformance.
    /// Deletes all rows that match the core data request.
    public static func deleteAll(
        with manager: SimpleSerializedCoreDataManageable?,
        alterFetchRequest: @escaping AlterFetchRequestClosure<EntityType>
    ) -> Bool {
        let manager = manager ?? defaultManager
        let isDeleted = manager.deleteAll(alterFetchRequest: alterFetchRequest)
        return isDeleted
    }
    
    /// Convenience version of deleteAll:manager:alterFetchRequest (manager not required).
    public static func deleteAll(
        alterFetchRequest: @escaping AlterFetchRequestClosure<EntityType>
    ) -> Bool {
        return deleteAll(with: nil, alterFetchRequest: alterFetchRequest)
    }
    
    /// Convenience version of deleteAll:manager:alterFetchRequest (no parameters required).
    public static func deleteAll() -> Bool {
        return deleteAll(with: nil) { _ in }
    }
}
