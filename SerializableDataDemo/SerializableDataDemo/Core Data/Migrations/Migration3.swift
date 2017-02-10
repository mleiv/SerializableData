//
//  Migration2.swift
//  SerializableDataDemo
//
//  Created by Emily Ivie on 2/8/17.
//  Copyright © 2017 Emily Ivie. All rights reserved.
//

import CoreData

    
/// Rules of this migration:
///
///     - This migration has to use a different column name for data column than prior string column
///         (It requires an equivalency otherwise, and then fails before reaching here because data != string)
///
public class Migration3: NSEntityMigrationPolicy {

    /// Affected tables - ignore all other tables.
    private let changeTables = ["Persons"]

    /// Converts a serializedData String to Data.
    private func changeType(fromSerializedData serializedDataString: String?) -> Data {
        if let serializedDataString = serializedDataString,
            let person = CoreDataPerson(serializedString: serializedDataString),
            let data = person.serializedData {
            return data
        }
        return Data()
    }
    
    /// Reads through all Persons rows and converts String to Data for serializedData.
    override public func createDestinationInstances(
        forSource sInstance: NSManagedObject,
        in mapping: NSEntityMapping,
        manager: NSMigrationManager
    ) throws {
        guard let name = sInstance.entity.name, changeTables.contains(name) else {
            return try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
        }
        let dInstance = NSEntityDescription.insertNewObject(forEntityName: name, into: manager.destinationContext)
        for (key, _) in sInstance.entity.attributesByName {
            if name == "Persons" && key == "serializedDataOld",
                let value = sInstance.value(forKey: "serializedDataOld") {
                dInstance.setValue(
                    changeType(fromSerializedData: value as? String),
                    forKey: "serializedData"
                )
            } else {
                dInstance.setValue(
                    sInstance.value(forKey: key),
                    forKey: key
                )
            }
        }
        manager.associate(sourceInstance: sInstance, withDestinationInstance: dInstance, for: mapping)
    }
}
