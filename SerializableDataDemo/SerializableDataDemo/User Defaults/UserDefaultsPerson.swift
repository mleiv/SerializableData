//
//  UserDefaultsPerson.swift
//
//  Copyright 2017 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.

import Foundation

public struct UserDefaultsPerson {
    
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

extension UserDefaultsPerson: SerializedDataStorable {

    public func getData() -> SerializableData {
        var list = [String: SerializedDataStorable?]()
        list["name"] = name
        list["profession"] = profession
        list["organization"] = organization
        list["notes"] = notes
        list["createdDate"] = createdDate
        list["modifiedDate"] = modifiedDate
        return SerializableData.safeInit(list)
    }
    
}

extension UserDefaultsPerson: SerializedDataRetrievable {
    
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

extension UserDefaultsPerson: Equatable {}

public func ==(a: UserDefaultsPerson, b: UserDefaultsPerson) -> Bool { // not true equality, just same db row
    return a.name == b.name
}

//MARK: NSUserDefaults

extension UserDefaultsPerson: UserDefaultsStorable {

    public static var userDefaultsEntityName: String { return "Persons" }
    
    public func isEqual<T : UserDefaultsStorable>(_ item: T) -> Bool {
        if let item = item as? UserDefaultsPerson {
            return item.name == name
        }
        return false
    }
    
    public mutating func save() -> Bool {
        let isSaved = UserDefaultsManager.save(item: self)
        return isSaved
    }
    
    public mutating func delete() -> Bool {
        let isDeleted = UserDefaultsManager.delete(item: self)
        return isDeleted
    }
    
    
    // we do not delete data
    
    public static func get(name: String) -> UserDefaultsPerson? {
        return UserDefaultsManager.get() { $0.name == name }
    }
    
    public static func getAll() -> [UserDefaultsPerson] {
        let all: [UserDefaultsPerson] = UserDefaultsManager.getAll()
        return all
    }
    
}
