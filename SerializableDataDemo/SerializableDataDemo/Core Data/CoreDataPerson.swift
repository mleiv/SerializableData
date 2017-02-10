//
//  CoreDataPerson.swift
//  MassEffectTracker
//
//  Created by Emily Ivie on 9/6/15.
//  Copyright © 2015 urdnot. All rights reserved.
//

import Foundation

public struct CoreDataPerson {
    
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

//MARK: Equatable

extension CoreDataPerson: Equatable {}

public func ==(a: CoreDataPerson, b: CoreDataPerson) -> Bool { // not true equality, just same db row
    return a.name == b.name
}

//MARK: CoreData

import CoreData

extension CoreDataPerson: CoreDataStorableExtra {
    public typealias CoreDataEntityType = Persons

    public static var coreDataEntityName: String { return "Persons" }
    
    public func setAdditionalColumnsOnSave(
        coreDataManager: CoreDataManager,
        coreItem: NSManagedObject
    ) {
        // only save searchable columns, everything else goes in serializedData
        guard let coreItem = coreItem as? CoreDataEntityType else { return }
        coreItem.name = name
    }
    
    public func setIdentifyingPredicate(
        fetchRequest: NSFetchRequest<NSFetchRequestResult>
    ) {
        fetchRequest.predicate = NSPredicate(format: "(name = %@)", name)
    }
    
    public static func get(
        name: String,
        coreDataManager: CoreDataManager? = nil
    ) -> CoreDataPerson? {
        let manager = coreDataManager ?? CoreDataManager()
        return manager?.get() { fetchRequest in
            fetchRequest.predicate = NSPredicate(format: "(name = %@)", name)
        }
    }
    
}
