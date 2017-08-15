//
//  UserDefaultsManager.swift
//
//  Copyright 2017 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.

import Foundation

public typealias AlterUserDefaultsRequestClosure<T> = ((T)->Bool)

public enum UserDefaultsManagerError : Error {
    case notFound
    case failedToInitializedObject
}

/// Not so efficient as CoreData, since it retrieves the whole list of objects, but hey, still works. :/
public struct UserDefaultsManager {
    
    public static func save<T: UserDefaultsStorable>(item: T) -> Bool {
        var all: [T] = getAll()
        if let index = all.index(where: { item.isEqual($0) }) {
            all[index] = item
        } else {
            all.append(item)
        }
        return saveAll(items: all)
    }
    
    static func saveAll<T: UserDefaultsStorable>(items: [T]) -> Bool {
        let defaults = UserDefaults.standard
        let serializedString: String
        if let data = try? SimpleCoreDataManager.current.encoder.encode(items),
            let string = String(data: data, encoding: .utf8) {
            serializedString = string
        } else {
            serializedString = ""
        }
        defaults.set(serializedString, forKey: T.userDefaultsEntityName)
        return true
    }
    
    public static func delete<T: UserDefaultsStorable>(item: T) -> Bool {
        var all: [T] = getAll()
        if let index = all.index(where: { item.isEqual($0) }) {
            all.remove(at: index)
        } else {
            return false
        }
        return saveAll(items: all)
    }
    
    public static func get<T: UserDefaultsStorable>(filter: AlterUserDefaultsRequestClosure<T> = { _ in true }) -> T? {
        let all: [T] = getAll(filter: filter)
        return all.first
    }
    
    public static func getAll<T: UserDefaultsStorable>(filter: AlterUserDefaultsRequestClosure<T> = { _ in true }) -> [T] {
        do {
            let defaults = UserDefaults.standard
            if let serializedString = defaults.object(forKey: T.userDefaultsEntityName) as? String,
                let data = serializedString.data(using: .utf8) {
                let all = try SimpleCoreDataManager.current.decoder.decode([T].self, from: data)
                return all.filter(filter)
            }
        } catch let saveError as NSError {
            print("getAll failed for \(T.userDefaultsEntityName): \(saveError.localizedDescription)")
        }
        return []
    }
    
}
