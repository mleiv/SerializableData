//
//  CoreDataPerson.swift
//  MassEffectTracker
//
//  Created by Emily Ivie on 9/6/15.
//  Copyright © 2015 urdnot. All rights reserved.
//

import Foundation

public struct CoreDataPerson {
    
    public private(set) var createdDate = NSDate()
    public var modifiedDate = NSDate()
    
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
        print(SerializableData(list).serializedString)
        return SerializableData(list)
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
    
    public mutating func setData(data: SerializableData) {
        //mandatory data (probably already set, but allow it to be set again if setData() was called separately)
        name = data["name"]?.string ?? name
        
        //optional values:
        createdDate = data["createdDate"]?.date ?? NSDate()
        modifiedDate = data["modifiedDate"]?.date ?? NSDate()
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

extension CoreDataPerson: CoreDataStorable {

    public static var coreDataEntityName: String { return "Persons" }
    
    public func setAdditionalColumns(coreItem: NSManagedObject) {
        // only save searchable columns, everything else goes in serializedData
        coreItem.setValue(name, forKey: "name")
    }
    
    public func setIdentifyingPredicate(fetchRequest: NSFetchRequest) {
        fetchRequest.predicate = NSPredicate(format: "(name = %@)", name)
    }
    
    public mutating func save() -> Bool {
        let isSaved = CoreDataManager.save(self)
        return isSaved
    }
    
    public mutating func delete() -> Bool {
        let isDeleted = CoreDataManager.delete(self)
        return isDeleted
    }
    
    public static func get(name: String) -> CoreDataPerson? {
        return CoreDataManager.get(CoreDataPerson(name: name))
    }
    
    public static func getAll() -> [CoreDataPerson] {
        let all: [CoreDataPerson] = CoreDataManager.getAll()
        return all
    }
    
}