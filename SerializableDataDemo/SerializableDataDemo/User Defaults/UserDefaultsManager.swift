//
//  UserDefaultsManager.swift
//
//  Copyright 2015 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.
//


import Foundation

public enum UserDefaultsManagerError : ErrorType {
    case NotFound
    case FailedToInitializedObject
}

/// Not so efficient as CoreData, since it retrieves the whole list of objects, but hey, still works. :/
public struct UserDefaultsManager {
    
    public static func save<T: UserDefaultsStorable>(item: T) -> Bool {
        var all: [T] = getAll()
        if let index = all.indexOf({ item.isEqual($0) }) {
            all[index] = item
        } else {
            all.append(item)
        }
        return saveAll(all)
    }
    
    private static func saveAll<T: UserDefaultsStorable>(items: [T]) -> Bool {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(SerializableData(items.map{ $0.getData() }).serializedString, forKey: T.userDefaultsEntityName)
        return true
    }
    
    public static func delete<T: UserDefaultsStorable>(item: T) -> Bool {
        var all: [T] = getAll()
        if let index = all.indexOf({ item.isEqual($0) }) {
            all.removeAtIndex(index)
        } else {
            return false
        }
        return saveAll(all)
    }
    
    public static func get<T: UserDefaultsStorable>(item: T) -> T? {
        let all: [T] = getAll()
        return all.filter{ item.isEqual($0) }.first
    }
    
    public static func getAll<T: UserDefaultsStorable>() -> [T] {
        do {
            let defaults = NSUserDefaults.standardUserDefaults()
            if let serializedString = defaults.objectForKey(T.userDefaultsEntityName) as? String {
                let serializedList = try SerializableData(jsonString: serializedString)
                let all = (serializedList.array ?? []).map {
                    return T(data: $0)
                }.filter{ $0 != nil }.map{ $0! }
                return all
            }
        } catch let saveError as NSError {
            print("getAll failed for \(T.userDefaultsEntityName): \(saveError.localizedDescription)")
        }
        return []
    }
    
}