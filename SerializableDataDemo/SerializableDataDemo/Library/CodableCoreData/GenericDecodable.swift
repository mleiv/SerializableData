//
//  GenericDecodable.swift
//  SerializableDataDemo
//
//  Created by Emily Ivie on 8/14/17.
//  Copyright © 2017 Emily Ivie. All rights reserved.
//

import Foundation

/// Required to do a chained generic init() beginning with JSONDecoder.decode(...)
///
/// See: CodableCoreDataStorable::init?(coreItem: EntityType)
struct GenericDecodable: Decodable {
    let decoder: Decoder
    public init(from decoder: Decoder) throws {
        self.decoder = decoder
    }
}
