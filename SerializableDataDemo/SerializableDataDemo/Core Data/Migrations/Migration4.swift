//
//  Migration4.swift
//  SerializableDataDemo
//
//  Created by Emily Ivie on 2/20/17.
//  Copyright © 2017 Emily Ivie. All rights reserved.
//

import CoreData

public class Migration4: NSEntityMigrationPolicy {

    /// Affected tables - ignore all other tables.
    private let changeTables = ["Persons"]
    
    /// Reads through all Persons rows and adds an id.
    override public func createDestinationInstances(
        forSource sInstance: NSManagedObject,
        in mapping: NSEntityMapping,
        manager: NSMigrationManager
    ) throws {
        guard let name = sInstance.entity.name, changeTables.contains(name) else {
            return try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
        }
        let dInstance = NSEntityDescription.insertNewObject(forEntityName: name, into: manager.destinationContext)
        if let serializedData = sInstance.value(forKey: "serializedData") as? Data,
            let data = try? SerializableData(serializedData: serializedData),
            let item = CoreDataPerson(data: data, isAllowNoId: true) {
            dInstance.setValue(
                item.serializedData,
                forKey: "serializedData"
            )
            dInstance.setValue(
                item.name,
                forKey: "name"
            )
            dInstance.setValue(
                item.id.uuidString,
                forKey: "id"
            )
            manager.associate(sourceInstance: sInstance, withDestinationInstance: dInstance, for: mapping)
        } else {
            fatalError("Could not migrate row")
        }
    }
}
