//
//  SerializedDataStorable.swift
//
//  Copyright 2017 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.
//

import UIKit

// MARK: SerializedDataStorable Protocol
// (can be extended to any type you want, just implement getData)

public protocol SerializedDataStorable {
    // any struct or object can be stored in SerializableData, provided it adheres to this protocol

    func getData() -> SerializableData // implement this
    var serializedString: String { get } // implemented by protocol
}

// default protocol functions:

extension SerializedDataStorable {
    public var serializedString: String {
        return getData().jsonString
    }
    public func getData() -> SerializableData { // default implementation
        if let data = self as? SerializableData {
            return data
        }
        var data = SerializableData()
        if !(self is NSNull) {
            data.contents = .valueType(self)
        }
        return data
    }
}

public protocol SerializedDataStorableFlatValue {}

// default applications of storable protocol

extension Bool: SerializedDataStorable, SerializedDataStorableFlatValue {}
extension String: SerializedDataStorable, SerializedDataStorableFlatValue {}
extension Int: SerializedDataStorable, SerializedDataStorableFlatValue {}
extension Double: SerializedDataStorable, SerializedDataStorableFlatValue {}
extension Float: SerializedDataStorable, SerializedDataStorableFlatValue {}
extension CGFloat: SerializedDataStorable, SerializedDataStorableFlatValue {}
extension NSString: SerializedDataStorable, SerializedDataStorableFlatValue {}
extension NSNumber: SerializedDataStorable, SerializedDataStorableFlatValue {}
extension NSNull: SerializedDataStorable, SerializedDataStorableFlatValue {}

extension Date: SerializedDataStorable, SerializedDataStorableFlatValue {
    public func getData() -> SerializableData {
        return SerializableData.safeInit(date: self) // special case
    }
}
extension URL: SerializedDataStorable, SerializedDataStorableFlatValue {
    public func getData() -> SerializableData {
        return SerializableData.safeInit(self.absoluteString)
    }
}
extension Data: SerializedDataStorable, SerializedDataStorableFlatValue {
    public func getData() -> SerializableData {
        return SerializableData.init(data: self) // special case
    }
}

extension SerializableData: SerializedDataStorable {
    public func getData() -> SerializableData { return self }
}

// You cannot declare Array/Dictionary -both- SerializedDataStorable
// and containing SerializedDataStorable type (it's one or the other)
//extension Sequence where Iterator.Element == (T: String, U: SerializedDataStorable?) {
//    func getData() -> SerializableData {
//        return SerializableData( Dictionary( map { ($0.0, SerializableData($0.1) ) } ) )
//    }
//}
//extension Sequence where Iterator.Element == SerializedDataStorable? {
//    func getData() -> SerializableData {
//        return SerializableData( Array( map { SerializableData($0) } ) )
//    }
//}
