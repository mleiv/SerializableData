//
//  SerializableData.swift
//
//  Copyright 2015 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see http://opensource.org/licenses/MIT
//  Redistributions of files must retain the above copyright notice.
//

import UIKit

public enum SerializableDataError : Error {
    case parsingError
    case fileLoadError
    case typeMismatch
    case missingRequiredField
}

/**
 * Example:
 *
        let x = SerializableData(["something": 3.05] as [String: SerializedDataStorable?])
        print(x["something"]?.string) //Optional("3.05")
        print(x["something"]?.double) //Optional(3.05)
*/
public struct SerializableData {
    
    internal enum StorageType {
        case none
        case valueType(SerializedDataStorable)
        indirect case dictionaryType([String: SerializableData])
        indirect case arrayType([SerializableData])
        
        internal func isNone() -> Bool {
            if case .none = self { return true } else { return false }
        }
        internal func isValue() -> Bool {
            if case .valueType(_) = self { return true } else { return false }
        }
        internal func isDictionary() -> Bool {
            if case .dictionaryType(_) = self { return true } else { return false }
        }
        internal func isArray() -> Bool {
            if case .arrayType(_) = self { return true } else { return false }
        }
    }
    internal var contents = StorageType.none
    
    //MARK: Initializers
    
    public init() {}
    
    public init<T>(_ data: T) throws {
        switch data {
            case let v as [SerializableData]:
                contents = .arrayType(v)
            case let v as [SerializedDataStorable?]: 
                var a: [SerializableData] = []
                for (value) in v { a.append( value?.getData() ?? SerializableData() ) }
                contents = .arrayType(a)
            case let v as [AnyObject]:
                var a: [SerializableData] = []
                for (value) in v { a.append( try SerializableData(value) ) }
                contents = .arrayType(a)
            case let v as [String: SerializableData]:
                contents = .dictionaryType(v)
            case let v as [String: SerializedDataStorable?]: 
                var a: [String: SerializableData] = [:]
                for (key, value) in v { a[key] = value?.getData() ?? SerializableData()  }
                contents = .dictionaryType(a)
            case let v as [String: AnyObject]:
                var a: [String: SerializableData] = [:]
                for (key, value) in v { a[key] = try SerializableData(value) }
                contents = .dictionaryType(a)
            case let v as SerializedDataStorable:
                if v is SerializedDataStorableFlatValue {
                    contents = .valueType(v)
                } else {
                    self = v.getData()
                }
            case nil: break
            default: throw SerializableDataError.parsingError
        }
    }
    
    public static func safeInit<T>(_ data: T) -> SerializableData {
        return (try? SerializableData(data)) ?? SerializableData()
    }
    
    /// - Parameter date: does date to string conversion before storing value
    public init(date: Date) throws {
       if let sDate = stringFromDate(date) {
            contents = .valueType(sDate)
        } else {
            throw SerializableDataError.parsingError
        }
    }
    
    public static func safeInit(date: Date) -> SerializableData {
       return (try? SerializableData(date: date)) ?? SerializableData()
    }
    
    /// - Parameter data: does date to string conversion before storing value
    public init(data: Data) {
        let sData = data.base64EncodedString()
        contents = .valueType(sData)
    }
    
    /// Note: You probably want to run this on a background thread for large data
    /// - Parameter fileName: a file inside documents folder, presumably of json format
    public init(fileName: String) throws {
        if let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            let path = (documents as NSString).appendingPathComponent(fileName)
            if let d = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                try self.init(jsonData: d)
                return
            }
        }
        throw SerializableDataError.fileLoadError
    }

    /// Note: You probably want to run this on a background thread for large data
    /// - Parameter jsonData: parses a json list of Data format. Throws error if it can't parse it/make it SerializableData.
    public init(jsonData: Data) throws {
        try self.init(serializedData: jsonData)
    }
    
    public init(serializedData data: Data) throws {
        do {
            let d = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
            try self.init(d)
        } catch {
            throw SerializableDataError.parsingError
        }
    }
    
    /// Note: You probably want to run this on a background thread for large data
    /// - Parameter jsonString: parses a json-formatted string. Throws error if it can't parse it/make it SerializableData.
    public init(jsonString: String) throws {
        try self.init(serializedString: jsonString)
    }
    
    public init(serializedString json: String) throws {
        if let data = (json as NSString).data(using: String.Encoding.utf8.rawValue) {
            try self.init(jsonData: data)
        } else {
            throw SerializableDataError.parsingError
        }
    }
}


extension SerializableData {
//MARK: Return stored data
    
    /// - Returns: Whatever type requested, if it is possible to convert the data into that format.
    public func value<T>() -> T? {
        let formatter = NumberFormatter()
        switch contents {
        case .none: return nil
        case .valueType(let v):
//            if let tValue = v as? T {
//                return tValue
//            }
            let s = String(describing: v)
            if s == "<null>" {
                return nil
            }
            // fun times: json is often ambiguous about whether it's a string or a number
            if Bool.self == T.self, let tValue = NSString(string: s).boolValue as? T {
                return tValue
            } else if Int.self == T.self, let tValue = formatter.number(from: s)?.intValue as? T {
                return tValue
            } else if Float.self == T.self, let tValue = formatter.number(from: s)?.floatValue as? T {
                return tValue
            } else if Double.self == T.self, let tValue = formatter.number(from: s)?.doubleValue as? T {
                return tValue
            } else if CGFloat.self == T.self, let v = formatter.number(from: s)?.doubleValue,
                      let tValue = CGFloat(v) as? T {
                return tValue
            } else if Date.self == T.self, let tValue = dateFromString(s) as? T {
                return tValue
            } else if URL.self == T.self, let tValue = URL(string: s) as? T {
                return tValue
            } else if Data.self == T.self, let tValue = Data(base64Encoded: s, options: .ignoreUnknownCharacters) as? T {
                return tValue
            } else if let tValue = formatter.number(from: s) as? T { //NSNumber
                return tValue
            } else if let tValue = s as? T { // string requested
                return tValue
            }
            return nil
        case .dictionaryType(let d):
            if let tValue = d as? T {
                return tValue
            } else {
                return nil
            }
        case .arrayType(let a):
            if let tValue = a as? T {
                return tValue
            } else {
                return nil
            }
        }
    }
    
    /// - Returns: Optional(String) if this object can be one (most things can)
    public var string: String? { return value() as String? }
    /// - Returns: Optional(Bool) if this object can be converted to one
    public var bool: Bool? { return value() as Bool? }
    /// - Returns: Optional(Int) if this object can be converted to one
    public var int: Int? { return value() as Int? }
    /// - Returns: Optional(Float) if this object can be converted to one
    public var float: Float? { return value() as Float? }
    /// - Returns: Optional(Double) if this object can be converted to one
    public var double: Double? { return value() as Double? }
    /// - Returns: Optional(CGFloat) if this object can be converted to one
    public var cgFloat: CGFloat? { return value() as CGFloat? }
    /// - Returns: Optional(NSNumber) if this object can be converted to one
    public var nsNumber: NSNumber? { return value() as NSNumber? }
    /// - Returns: Optional(URL) if this object can be converted to one
    public var url: URL? { return value() as URL? }
    /// - Returns: Optional(Date) if this object can be converted to one
    public var date: Date? { return value() as Date? }
    /// - Returns: Optional(Data) if this object can be converted to one
    public var data: Data? { return value() as Data? }
    /// - Returns: Optional(NSDate) if this object can be converted to one
    public var isNil: Bool { return contents == StorageType.none }
    
    /// - Parameter value: A date string of format "YYYY-MM-dd HH:mm:ss"
    /// - Returns: Optional(NSDate)
    func dateFromString(_ value: String) -> Date? {
        let dateFormatter = DateFormatter()
        //add more flexible parsing later?
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd' 'HH':'mm':'ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let date = dateFormatter.date(from: value)
        return date
    }
    
    /// - Parameter value: NSDate
    /// - Returns: Optional(String) of format "YYYY-MM-dd HH:mm:ss"
    func stringFromDate(_ value: Date) -> String? {
        let dateFormatter = DateFormatter()
        //add more flexible parsing later
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter.string(from: value)
    }
}


extension SerializableData {
//MARK: subscript and array access
    
    // SerializableData does not implement full sequence/collection type because you should be using .array and .dictionary instead (trust me, you will find it is far easier when dealing with mixed data-!).
    // But I've included append and subscript just to make editing your data a little bit easier.
    
    public subscript(index: String) -> SerializableData? {
        get {
            if case .dictionaryType(let d) = contents {
                return d[index]
            }
            return nil
        }
        set {
            if case .dictionaryType(let d) = contents {
                var newDictionary: [String: SerializableData] = d
                newDictionary[index] = newValue ?? SerializableData()
                contents = .dictionaryType(newDictionary)
            } else if case .none = contents {
                contents = .dictionaryType([index: newValue ?? SerializableData()] as [String: SerializableData])
            } else {
                assert(false, "Key does not point to dictionary-type data")
                // someday: throw SerializableDataError.TypeMismatch
            }
        }
    }
    public subscript(index: Int) -> SerializableData? {
        get {
            if case .arrayType(let a) = contents {
                return a[index]
            }
            return nil
        }
        set {
            if case .arrayType(let a) = contents {
                var newArray: [SerializableData] = a
                newArray.append(newValue ?? SerializableData())
                contents = .arrayType(newArray)
            } else if case .none = contents {
                contents = .arrayType([newValue ?? SerializableData()] as [SerializableData])
            } else {
                assert(false, "Key does not point to array-type data")
                // someday: throw SerializableDataError.TypeMismatch
            }
        }
    }
    
    /// - Parameter value: Any value type. If value cannot be converted to SerializableData, or if this SerializableData object is not an array, then it throws error. (If this object is .None, then it changes to an array of the new value.)
    public mutating func append<T>(_ value: T?) throws {
        guard case .arrayType(var a) = contents else {
            throw SerializableDataError.typeMismatch
        }
        a.append([ try SerializableData(value) ])
        contents = .arrayType(a)
    }
    
    /// - Returns: A dictionary if this object is one
    public var dictionary: [String: SerializableData]? {
        if case .dictionaryType(let d) = contents {
            return d
        }
        return nil
    }
    
    /// - Returns: An array if this object is one
    public var array: [SerializableData]? {
        if case .arrayType(let a) = contents {
            return a
        }
        return nil
    }
}


extension SerializableData {
//MARK: formatting data for other uses
    
    /// Note: You probably want to run this on a background thread for large data
    /// - Parameter fileName: writes file of this name to documents folder; can be retrieved via init(file:)
    /// - Returns: true if write was a success
    public func store(fileName: String) -> Bool {
        guard let data = toData(),
           let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        else {
            return false
        }
        let path = (documents as NSString).appendingPathComponent(fileName)
        if ((try? data.write(to: URL(fileURLWithPath: path), options: [.atomic])) != nil) == true {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }
    
    /// - Parameter fileName: deletes file of this name from documents folder
    /// - Returns: true if delete was a success
    public func delete(fileName: String) -> Bool {
        guard let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        else {
            return false
        }
        let path = (documents as NSString).appendingPathComponent(fileName)
        if let _ = try? FileManager.default.removeItem(atPath: path) , !FileManager.default.fileExists(atPath: path) {
            return true
        }
        return false
    }
    
    /// - Returns: AnyObject (closest to the format used to create the SerializableData object originally)
    public var anyObject: AnyObject {
        switch contents {
        case .valueType(let v):
            return v as AnyObject
        case .dictionaryType(let d):
            let list = NSMutableDictionary()
            for (key, value) in d {
                list[key] = value.anyObject
            }
            return list
        case .arrayType(let a):
            let list = NSMutableArray()
            for (value) in a {
                list.add(value.anyObject)
            }
            return list
        default:
            return NSNull()
        }
    }

    public var nsData: Data? {
        return toData()
    }
    /// - Returns: A Data object
    public func toData() -> Data? {
        if case .none = contents {
            // can't make a json object with *just* nil (NSNull inside array/dictionary is okay)
            return nil
        }
        do {
            return try JSONSerialization.data(withJSONObject: anyObject, options: JSONSerialization.WritingOptions.prettyPrinted)
        } catch {
            return nil
        }
    }
    
    //MARK: jsonString
    
    /// - Returns: A flattened json string
    public var jsonString: String {
        switch contents {
        case .valueType(let v): return "\(v)"
        case .dictionaryType(_): fallthrough
        case .arrayType(_):
            if let d = toData(), let jsonString = String(data: d, encoding: String.Encoding.utf8) {
                return jsonString
            }
            fallthrough
        default: return ""
        }
    }

    //MARK: urlString
    
    /// - Returns: A flattened String in format "key=value&key=value"
    public var urlString: String {
        switch contents {
        case .valueType(_): return SerializableData.urlEncode(self.jsonString)
        case .dictionaryType(let d): return SerializableData.urlString(d)
        case .arrayType(let a): return SerializableData.urlString(a)
        default: return ""
        }
    }
    
    /// - Parameter list: a dictionary to convert
    /// - Parameter prefix: - an optional prefix to use before the key (necessary for nested data)
    /// - Returns: A flattened String in format "key=value&key=value"
    public static func urlString(_ list: [String: SerializableData], prefix: String = "") -> String {
        var urlStringValue = ""
        for (key, value) in list {
            let prefixedKey = prefix != "" ? "\(prefix)[\(key)]" : key
            switch value.contents {
            case .valueType(let v): urlStringValue += "\(urlEncode(prefixedKey))=\(urlEncode(v))&"
            case .dictionaryType(let d): urlStringValue += "\(urlString(d, prefix: prefixedKey))&"
            case .arrayType(let a): urlStringValue += "\(urlString(a, prefix: prefixedKey))&"
            default: urlStringValue += "\(self.urlEncode(prefixedKey))=&"
            }
        }
        return urlStringValue.isEmpty ? "" : urlStringValue.stringFrom(0, to: -1)
    }
    
    /// - Parameter list: an array to convert
    /// - Parameter prefix: - an optional prefix to use before the key (necessary for nested data)
    /// - Returns: A flattened String in format "key=value&key=value"
    public static func urlString(_ list: [SerializableData], prefix: String = "") -> String {
        var urlStringValue = ""
        for (value) in list {
            let prefixedKey = prefix != "" ? "\(prefix)[]" : ""
            let prefixHere = prefixedKey != "" ? "\(self.urlEncode(prefixedKey))=" : ""
            switch value.contents {
            case .valueType(let v): urlStringValue += prefixHere + urlEncode(v) + "&"
            case .dictionaryType(let d): urlStringValue += "\(urlString(d, prefix: prefixedKey))&"
            case .arrayType(let a): urlStringValue += "\(urlString(a, prefix: prefixedKey))&"
            default: urlStringValue += prefixHere + ","
            }
        }
        return urlStringValue.isEmpty ? "" : urlStringValue.stringFrom(0, to: -1)
    }

    /// - Parameter unescaped: The string to be escaped
    /// - Returns: An escaped String in format "something%20here"
    public static func urlEncode(_ unescaped: SerializedDataStorable) -> String {
        let characterSet = NSMutableCharacterSet.alphanumeric()
        characterSet.addCharacters(in: "-._~")
        if !(unescaped is NSNull), let escaped = "\(unescaped)".addingPercentEncoding(withAllowedCharacters: characterSet as CharacterSet) {
            return escaped
        }
        return ""
    }
}

//MARK: LiteralConvertible Protocols

extension SerializableData: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
    }
}
extension SerializableData: ExpressibleByStringLiteral {
    public init(stringLiteral s: StringLiteralType) {
        contents = .valueType(s)
    }
    public init(extendedGraphemeClusterLiteral s: StringLiteralType) {
        contents = .valueType(s)
    }
    public init(unicodeScalarLiteral s: StringLiteralType) {
        contents = .valueType(s)
    }
}
extension SerializableData: ExpressibleByIntegerLiteral {
    public init(integerLiteral i: IntegerLiteralType) {
        contents = .valueType(i)
    }
}
extension SerializableData: ExpressibleByFloatLiteral {
    public init(floatLiteral f: FloatLiteralType) {
        contents = .valueType(f)
    }
}
extension SerializableData: ExpressibleByBooleanLiteral {
    public init(booleanLiteral b: BooleanLiteralType) {
        contents = .valueType(b)
    }
}
extension SerializableData:  ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = SerializedDataStorable
    public init(dictionaryLiteral tuples: (Key, Value)...) {
        contents = .dictionaryType(Dictionary(tuples.map { ($0.0, $0.1.getData()) }))
    }
    public init(dictionaryLiteral tuples: (Key, Value?)...) {
        contents = .dictionaryType(Dictionary(tuples.map { ($0.0, $0.1?.getData()  ?? SerializableData()) }))
    }
}
extension SerializableData:  ExpressibleByArrayLiteral {
    public typealias Element = SerializedDataStorable
    public init(arrayLiteral elements: Element...) {
        contents = .arrayType(elements.map { $0.getData() })
    }
    public init(arrayLiteral elements: Element?...) {
        contents = .arrayType(elements.map { $0?.getData() ?? SerializableData() })
    }
}


extension SerializableData: Equatable {}
//MARK: - Equatable Protocol

public func ==(lhs: SerializableData, rhs: SerializableData) -> Bool {
    return lhs.contents == rhs.contents
}
public func ==(lhs: SerializableData?, rhs: SerializableData?) -> Bool {
    return lhs?.contents ?? .none == rhs?.contents ?? .none
}
public func ==(lhs: SerializableData, rhs: SerializableData?) -> Bool {
    return lhs.contents == rhs?.contents ?? .none
}
public func ==(lhs: SerializableData?, rhs: SerializableData) -> Bool {
    return lhs?.contents ?? .none == rhs.contents
}

extension SerializableData.StorageType: Equatable {}

func == (lhs: SerializableData.StorageType, rhs: SerializableData.StorageType) -> Bool {
    switch (lhs, rhs) {
    case (.none, .none):
        return true
    case (.valueType(let v1), .valueType(let v2)):
        // do we care about type? I don't think so...
        return "\(v1)" == "\(v2)"
    case (.dictionaryType(let v1), .dictionaryType(let v2)):
        return v1 == v2
    case (.arrayType(let v1), .arrayType(let v2)):
        return v1 == v2
    default: return false
    }
}

//extension SerializedDataStorable: Equatable {}
// we can't declare SerializedDataStorable Equatable or ArrayLiteralConvertible and DictionaryLiteralConvertible break, also would have to be declared on SerializedDataStorable initial definition
// also, since SerializableData is SerializedDataStorable, there is infinite looping. :(
//public func ==(lhs: SerializedDataStorable?, rhs: SerializedDataStorable?) -> Bool {
//    print("X")
//    return (lhs?.getData() ?? nil) == (rhs?.getData() ?? nil)
//}


extension SerializableData: CustomStringConvertible {
//MARK: - CustomStringConvertible Protocol

    public var description: String {
        switch contents {
        case .valueType(let s): return "\(s)"
        case .dictionaryType(let d):
            var description = ""
            for (key, value) in d {
                description += "\(key)=\(value.description),"
            }
            return !description.isEmpty ? "[\(description.stringFrom(0, to: -1))]" : "[]"
        case .arrayType(let a):
            var description = ""
            for (value) in a {
                description += "\(value.description),"
            }
            return !description.isEmpty ? "[\(description.stringFrom(0, to: -1))]" : "[]"
        default: return "nil"
        }
    }
}

