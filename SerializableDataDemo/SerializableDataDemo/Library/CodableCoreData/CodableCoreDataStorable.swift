//
//  CodableCoreDataStorable.swift
//
//  Copyright 2017 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.

import CoreData

public protocol CodableCoreDataStorable: Codable {

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

    /// Initializes value type from core data object with serialized data.
    init?(coreItem: EntityType)

// MARK: Optional/Default

    /// A reference to the current core data manager.
    static var defaultManager: CodableCoreDataManageable { get }

    /// Returns the CoreData row that is equal to this object.
    func entity(context: NSManagedObjectContext?) -> EntityType?

    /// String description of EntityType.
    static var entityName: String { get }

    /// String description of serialized data column in entity
    static var serializedDataKey: String { get }

    /// Sets core data values to match struct values (general).
    ///
    /// DON'T OVERRIDE.
    func setColumnsOnSave(
        coreItem: EntityType
    )

    /// Gets the struct to match the core data request.
    static func get(
        with manager: CodableCoreDataManageable?,
        alterFetchRequest: @escaping AlterFetchRequest<EntityType>
    ) -> Self?

    /// Gets the struct to match the core data request.
    static func getCount(
        with manager: CodableCoreDataManageable?,
        alterFetchRequest: @escaping AlterFetchRequest<EntityType>
    ) -> Int

    /// Gets all structs that match the core data request.
    static func getAll(
        with manager: CodableCoreDataManageable?,
        alterFetchRequest: @escaping AlterFetchRequest<EntityType>
    ) -> [Self]

    /// Saves the struct to core data.
    mutating func save(
        with manager: CodableCoreDataManageable?
    ) -> Bool

    /// Saves all the structs to core data.
    static func saveAll(
        items: [Self],
        with manager: CodableCoreDataManageable?
    ) -> Bool

    /// Deletes the struct's core data equivalent.
    mutating func delete(
        with manager: CodableCoreDataManageable?
    ) -> Bool

    /// Deletes all rows that match the core data request.
    static func deleteAll(
        with manager: CodableCoreDataManageable?,
        alterFetchRequest: @escaping AlterFetchRequest<EntityType>
    ) -> Bool
}

extension CodableCoreDataStorable {

    /// The closure type for editing fetch requests.
    public typealias AlterFetchRequest<T: NSManagedObject> = ((NSFetchRequest<T>) -> Void)

    /// Convenience - get the static version for easy instance reference.
    public var defaultManager: CodableCoreDataManageable {
        return Self.defaultManager
    }

    /// (Protocol default)
    /// Returns the CoreData row that is equal to this object.
    public func entity(context: NSManagedObjectContext?) -> EntityType? {
        let manager = type(of: defaultManager).init(context: context)
        return manager.getObject(item: self)
    }

    /// (Protocol default)
    /// String description of EntityType
    public static var entityName: String { return EntityType.description() }

    /// (Protocol default)
    /// String description of serialized data column in entity
    public static var serializedDataKey: String { return "serializedData" }

    /// (Protocol default)
    /// Initializes value type from core data object with serialized data.
    public init?(coreItem: EntityType) {
        // Warning: make sure parent runs this in the correct context/thread for this entity
        if let data = coreItem.value(forKey: Self.serializedDataKey) as? Data {
            do {
                let decodable = try Self.defaultManager.decoder.decode(GenericDecodable.self, from: data)
                try self.init(from: decodable.decoder)
                return
            } catch let decodeError {
                print("Error: decoding failed for \(Self.self): \(decodeError)")
            }
        }
        return nil
    }

    /// Sets core data values to match struct values (general).
    ///
    /// DON'T OVERRIDE.
    public func setColumnsOnSave(
        coreItem: EntityType
    ) {
        do {
            coreItem.setValue(try defaultManager.encoder.encode(self), forKey: Self.serializedDataKey)
        } catch let encodeError {
            print("Error: decoding failed for \(type(of: self)): \(encodeError)")
            coreItem.setValue(nil, forKey: Self.serializedDataKey)
        }
        setAdditionalColumnsOnSave(coreItem: coreItem)
    }

    /// (Protocol default)
    /// Gets the struct to match the core data request.
    public static func get(
        with manager: CodableCoreDataManageable?,
        alterFetchRequest: @escaping AlterFetchRequest<EntityType>
    ) -> Self? {
        return _get(with: manager, alterFetchRequest: alterFetchRequest)
    }

    /// Convenience version of get:manager:AlterFetchRequest<EntityType>
    ///    (manager not required).
    public static func get(
        alterFetchRequest: @escaping AlterFetchRequest<EntityType>
    ) -> Self? {
        return get(with: nil, alterFetchRequest: alterFetchRequest)
    }

    /// Convenience version of get:manager:AlterFetchRequest<EntityType>
    ///    (no parameters required).
    public static func get(
        with manager: CodableCoreDataManageable? = nil
    ) -> Self? {
        return get(with: manager) { _ in }
    }

    /// Root version of get:manager:AlterFetchRequest<EntityType> (you can still call this if you override that).
    ///
    /// DO NOT OVERRIDE.
    internal static func _get(
        with manager: CodableCoreDataManageable?,
        alterFetchRequest: @escaping AlterFetchRequest<EntityType>
    ) -> Self? {
        let manager = manager ?? defaultManager
        let one: Self? = manager.getValue(alterFetchRequest: alterFetchRequest)
        return one
    }

    /// (Protocol default)
    /// Gets the struct to match the core data request.
    public static func getCount(
        with manager: CodableCoreDataManageable?,
        alterFetchRequest: @escaping AlterFetchRequest<EntityType>
    ) -> Int {
        let manager = manager ?? defaultManager
        return manager.getCount(alterFetchRequest: alterFetchRequest)
    }

    /// Convenience version of getCount:manager:AlterFetchRequest<EntityType>
    ///    (manager not required).
    public static func getCount(
        alterFetchRequest: @escaping AlterFetchRequest<EntityType>
    ) -> Int {
        return getCount(with: nil, alterFetchRequest: alterFetchRequest)
    }

    /// Convenience version of getCount:manager:AlterFetchRequest<EntityType>
    ///    (AlterFetchRequest<EntityType> not required).
    public static func getCount(
        with manager: CodableCoreDataManageable?
    ) -> Int {
        return getCount(with: manager, alterFetchRequest: { _ in })
    }

    /// Convenience version of getCount:manager:AlterFetchRequest<EntityType>
    ///    (no parameters required).
    public static func getCount() -> Int {
        return getCount(with: nil) { _ in }
    }

    /// (Protocol default)
    /// Gets all structs that match the core data request.
    public static func getAll(
        with manager: CodableCoreDataManageable?,
        alterFetchRequest: @escaping AlterFetchRequest<EntityType>
    ) -> [Self] {
        return _getAll(with: manager, alterFetchRequest: alterFetchRequest)
    }

    /// Convenience version of getAll:manager:AlterFetchRequest<EntityType>
    ///    (manager not required).
    public static func getAll(
        alterFetchRequest: @escaping AlterFetchRequest<EntityType>
    ) -> [Self] {
        return getAll(with: nil, alterFetchRequest: alterFetchRequest)
    }

    /// Convenience version of getAll:manager:AlterFetchRequest<EntityType>
    ///    (no parameters required).
    public static func getAll(
        with manager: CodableCoreDataManageable? = nil
    ) -> [Self] {
        return getAll(with: manager) { _ in }
    }

    /// Root version of getAll:manager:AlterFetchRequest<EntityType> (you can still call this if you override that).
    ///
    /// DO NOT OVERRIDE.
    internal static func _getAll(
        with manager: CodableCoreDataManageable?,
        alterFetchRequest: @escaping AlterFetchRequest<EntityType>
    ) -> [Self] {
        let manager = manager ?? defaultManager
        let all: [Self] = manager.getAllValues(alterFetchRequest: alterFetchRequest)
        return all
    }

    /// (Protocol default)
    /// Saves the struct to core data.
    public mutating func save(
        with manager: CodableCoreDataManageable?
    ) -> Bool {
        let manager = manager ?? defaultManager
        let isSaved = manager.saveValue(item: self)
        return isSaved
    }

    /// Convenience version of save:manager
    ///    (no parameters required).
    public mutating func save() -> Bool {
        return save(with: nil)
    }

    /// (Protocol default)
    /// Saves all the structs to core data.
    public static func saveAll(
        items: [Self],
        with manager: CodableCoreDataManageable?
    ) -> Bool {
        guard !items.isEmpty else { return true }
        let manager = manager ?? defaultManager
        let isSaved = manager.saveAllValues(items: items)
        return isSaved
    }

    /// Convenience version of saveAll:items:manager
    ///    (manager not required).
    public static func saveAll(
        items: [Self]
    ) -> Bool {
        return saveAll(items: items, with: nil)
    }

    /// (Protocol default)
    /// Deletes the struct's core data equivalent.
    public mutating func delete(
        with manager: CodableCoreDataManageable?
    ) -> Bool {
        let manager = manager ?? defaultManager
        let isDeleted = manager.deleteValue(item: self)
        return isDeleted
    }

    /// Convenience version of delete:manager
    ///    (no parameters required).
    public mutating func delete() -> Bool {
        return delete(with: nil)
    }

    /// (Protocol default)
    /// Deletes all rows that match the core data request.
    public static func deleteAll(
        with manager: CodableCoreDataManageable?,
        alterFetchRequest: @escaping AlterFetchRequest<EntityType>
    ) -> Bool {
        let manager = manager ?? defaultManager
        let isDeleted = manager.deleteAll(alterFetchRequest: alterFetchRequest)
        return isDeleted
    }

    /// Convenience version of deleteAll:manager:AlterFetchRequest<EntityType>
    ///    (manager not required).
    public static func deleteAll(
        alterFetchRequest: @escaping AlterFetchRequest<EntityType>
    ) -> Bool {
        return deleteAll(with: nil, alterFetchRequest: alterFetchRequest)
    }

    /// Convenience version of deleteAll:manager:AlterFetchRequest<EntityType>
    ///    (AlterFetchRequest<EntityType> not required).
    public static func deleteAll(
        with manager: CodableCoreDataManageable?
    ) -> Bool {
        return deleteAll(with: manager) { _ in }
    }

    /// Convenience version of deleteAll:manager:AlterFetchRequest<EntityType>
    ///    (no parameters required).
    public static func deleteAll() -> Bool {
        return deleteAll(with: nil) { _ in }
    }
}

