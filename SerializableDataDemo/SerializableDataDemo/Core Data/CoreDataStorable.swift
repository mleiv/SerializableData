//
//  CoreDataStorable.swift (Abbreviated version for example only)
//
//  Copyright 2015 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.
//

import Foundation
import CoreData

public protocol CoreDataStorable: SerializedDataStorable, SerializedDataRetrievable {

    static var coreDataEntityName: String { get }
    
    var nsManagedObject: NSManagedObject? { get }
    
    func setIdentifyingPredicate(_ fetchRequest: NSFetchRequest<NSFetchRequestResult>)
    
    func setAdditionalColumns(_ coreItem: NSManagedObject)
    
    mutating func save() -> Bool
    mutating func delete() -> Bool
}

extension CoreDataStorable {

    public var nsManagedObject: NSManagedObject? {
        return CoreDataManager.fetchRow(self)
    }
    
}
