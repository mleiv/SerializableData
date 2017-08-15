//
//  JsonCoder.swift
//  MEGameTracker
//
//  Created by Emily Ivie on 8/14/17.
//  Copyright © 2017 Emily Ivie. All rights reserved.
//

import Foundation

public struct JsonCoder: CodableDecoder, CodableEncoder {
    public func encode<T>(_ value: T) throws -> Data where T : Encodable {
        return try encoder.encode(value)
    }
    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        return try decoder.decode(type, from: data)
    }
    public var decoder: JSONDecoder = {
        let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.formatted(dateFormatter)
        return decoder
    }()
    public var encoder: JSONEncoder = {
        let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = JSONEncoder.DateEncodingStrategy.formatted(dateFormatter)
        return encoder
    }()
}

