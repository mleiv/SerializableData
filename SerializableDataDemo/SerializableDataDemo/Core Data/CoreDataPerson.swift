//
//  CoreDataPerson.swift
//
//  Copyright 2017 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.

import Foundation

public struct CoreDataPerson: CodableCoreDataStorable {

    // MARK: Basic properties
    
    public private(set) var createdDate = Date()
    public var modifiedDate = Date()
    
    public var id: UUID
    public var name: String
    
    public var profession: String?
    public var organization: String?
    
    public var notes: String?
    
    // MARK: Basic initializer
    
    public init(id: UUID? = nil, name: String) {
        self.id = id ?? UUID()
        self.name = name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        profession = try container.decodeIfPresent(String.self, forKey: .profession) ?? ""
        organization = try container.decodeIfPresent(String.self, forKey: .organization) ?? ""
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        createdDate = try container.decodeIfPresent(Date.self, forKey: .createdDate) ?? Date()
        modifiedDate = try container.decodeIfPresent(Date.self, forKey: .createdDate) ?? Date()
    }
}

//MARK: CoreData

import CoreData

extension CoreDataPerson {

    /// Core data entity type for persons.
    public typealias EntityType = Persons
    
    /// Reference to current core data manager.
    public static var defaultManager: CodableCoreDataManageable { return SimpleCoreDataManager.current }

    public var serializedData: Data? {
        return try? CoreDataPerson.defaultManager.encoder.encode(self)
    }
    
    /// Copy this person's values to core data row.
    public func setAdditionalColumnsOnSave(
        coreItem: EntityType
    ) {
        // only save searchable columns, everything else goes in serializedData
        coreItem.id = id.uuidString
        coreItem.name = name
    }
    
    /// Identify this person's core data row.
    public func setIdentifyingPredicate(
        fetchRequest: NSFetchRequest<EntityType>
    ) {
        fetchRequest.predicate = NSPredicate(format: "(id = %@)", id.uuidString)
    }
    
    /// Convenience: get person by id.
    public static func get(
        id: String,
        with manager: CodableCoreDataManageable? = nil
    ) -> CoreDataPerson? {
        let manager = manager ?? defaultManager
        let person: CoreDataPerson? = manager.getValue() { fetchRequest in
            fetchRequest.predicate = NSPredicate(format: "(%K = %@)", #keyPath(Persons.id), id)
        }
        return person
    }
    
    /// Convenience: get person by name.
    public static func get(
        name: String,
        with manager: CodableCoreDataManageable? = nil
    ) -> CoreDataPerson? {
        let manager = manager ?? defaultManager
        let person: CoreDataPerson? = manager.getValue() { fetchRequest in
            fetchRequest.predicate = NSPredicate(format: "(%K = %@)", #keyPath(Persons.name), name)
        }
        return person
    }
}


// MARK: Sorting
extension CoreDataPerson {
    static func sort(_ a: CoreDataPerson, b: CoreDataPerson) -> Bool {
        return (a.name).localizedCaseInsensitiveCompare(b.name) == .orderedAscending // handle accented characters
    }
}

//MARK: Equatable

extension CoreDataPerson: Equatable {}

/// See setIdentifyingPredicate() above - this checks identifying properties for same-row equivalence.
public func ==(a: CoreDataPerson, b: CoreDataPerson) -> Bool {
    return a.id == b.id
}
