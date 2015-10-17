//
//  SerializedDataRetrievable.swift
//
//  Copyright 2015 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.
//

import Foundation


//MARK: SerializedDataRetrievable Protocol
// (can be extended to any type you want, just implement init?(data))

public protocol SerializedDataRetrievable {
    init?(data: SerializableData?) // implement this
    init?(serializedString json: String) throws // implement in class (not required in struct)
}

// default protocol functions:

extension SerializedDataRetrievable {
    public init?(serializedString json: String) throws {
        self.init(data: try SerializableData(jsonString: json))
    }
    /*
    // COPY THIS TO ANY SerializedDataRetrievable CLASSES:
    public required convenience init?(serializedString json: String) throws {
        self.init(data: try SerializableData(jsonString: json))
    }
    */
}

extension SerializedDataRetrievable where Self: SerializedDataStorable {
    public var serializedString: String {
        get { return getData().jsonString }
    }
}
