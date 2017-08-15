//
//  UserDefaultsPerson.swift
//
//  Copyright 2017 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.

import Foundation

public struct UserDefaultsPerson: Codable {
    
    public fileprivate(set) var createdDate = Date()
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
