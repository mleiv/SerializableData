//
//  UserDefaultsStorable.swift (Abbreviated version for example only)
//
//  Copyright 2015 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.
//

import Foundation
import CoreData

public protocol UserDefaultsStorable: SerializedDataStorable, SerializedDataRetrievable {

    static var userDefaultsEntityName: String { get }
    
    func isEqual<T:UserDefaultsStorable>(_ item: T) -> Bool
    
    mutating func save() -> Bool
    mutating func delete() -> Bool
}
