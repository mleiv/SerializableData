//
//  CoreDataPerson.swift
//
//  Copyright 2017 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.

import Foundation

public struct CoreDataPerson {

    // MARK: Basic properties
    
    public fileprivate(set) var createdDate = Date()
    public var modifiedDate = Date()
    
    public var name: String
    
    public var profession: String?
    public var organization: String?
    
    public var notes: String?
    
    // MARK: Basic initializer
    
    public init(name: String) {
        self.name = name
    }
}

//MARK: Saving/Retrieving Data

extension CoreDataPerson: SerializedDataStorable {
    
    /// Anything we want to save to core data should be put here.
    public func getData() -> SerializableData {
        var list = [String: SerializedDataStorable?]()
        list["name"] = name
        list["profession"] = profession
        list["organization"] = organization
        list["notes"] = notes
        list["createdDate"] = createdDate
        list["modifiedDate"] = modifiedDate
//        print(SerializableData(list).serializedString)
        return SerializableData.safeInit(list)
    }
    
}

extension CoreDataPerson: SerializedDataRetrievable {
    
    /// Recreation of person from SerializableData object.
    public init?(data: SerializableData?) {
        guard let data = data, let name = data["name"]?.string
        else {
            return nil
        }
        // required values:
        self.name = name
        // optional values:
        setData(data)
    }
    
    /// Anything we want to retrieve from core data should be put here.
    public mutating func setData(_ data: SerializableData) {
        //mandatory data (probably already set, but allow it to be set again if setData() was called separately)
        name = data["name"]?.string ?? name
        
        //optional values:
        createdDate = data["createdDate"]?.date ?? Date()
        modifiedDate = data["modifiedDate"]?.date ?? Date()
        profession = data["profession"]?.string
        organization = data["organization"]?.string
        notes = data["notes"]?.string
    }
    
}

//MARK: CoreData

import CoreData

extension CoreDataPerson: SimpleSerializedCoreDataStorable {

    /// Core data entity type for persons.
    public typealias EntityType = Persons
    
    /// Reference to current core data manager.
    public static var defaultManager: SimpleSerializedCoreDataManageable { return SimpleCoreDataManager.currentSerializable }
    
    /// Copy this person's values to core data row.
    public func setAdditionalColumnsOnSave(
        coreItem: EntityType
    ) {
        // only save searchable columns, everything else goes in serializedData
        coreItem.name = name
    }
    
    /// Identify this person's core data row.
    public func setIdentifyingPredicate(
        fetchRequest: NSFetchRequest<EntityType>
    ) {
        fetchRequest.predicate = NSPredicate(format: "(name = %@)", name)
    }
    
    /// Convenience: get person by name.
    public static func get(
        name: String,
        from manager: SimpleSerializedCoreDataManageable? = nil
    ) -> CoreDataPerson? {
        let manager = manager ?? defaultManager
        let person: CoreDataPerson? = manager.getValue() { fetchRequest in
            fetchRequest.predicate = NSPredicate(format: "(%K = %@)", #keyPath(Persons.name), name)
        }
        return person
    }
}

//MARK: Equatable

extension CoreDataPerson: Equatable {}

/// See setIdentifyingPredicate() above - this checks identifying properties for same-row equivalence.
public func ==(a: CoreDataPerson, b: CoreDataPerson) -> Bool {
    return a.name == b.name
}
