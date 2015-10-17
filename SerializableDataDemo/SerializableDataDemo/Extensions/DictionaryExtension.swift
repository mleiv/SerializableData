//
//  DictionaryExtension.swift
//
//  created 2015 Emily Ivie (cobbled together from many StackOverflow answers).
//  No license, everyone free to use.

import Foundation

extension Dictionary {
    // from: http://stackoverflow.com/a/24219069
    public init(_ pairs: [Element]) {
        self.init()
        for (k, v) in pairs {
            self[k] = v
        }
    }
}