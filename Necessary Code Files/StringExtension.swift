//
//  StringExtension.swift
//
//  created 2015 Emily Ivie (cobbled together from many StackOverflow answers).
//  No license, everyone free to use.

import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


extension String {
    /**
        Returns substring extracted from a string at start and end location.
    
        - parameter start:               Where to start (-1 acceptable)
        - parameter end:                 (Optional) Where to end (-1 acceptable) - default to end of string
        - returns: String
    */
    func stringFrom(_ start: Int, to end: Int? = nil) -> String {
        var maximum = self.characters.count
        
        let i = start < 0 ? self.endIndex : self.startIndex
        let ioffset = min(maximum, max(-1 * maximum, start))
        let startIndex = self.index(i, offsetBy: ioffset)
        
        maximum -= start
        
        let j = end < 0 ? self.endIndex : self.startIndex
        let joffset = min(maximum, max(-1 * maximum, end!))
        let endIndex = end != nil && end! < self.characters.count ? self.index(j, offsetBy: joffset) : self.endIndex
        return self.substring(with: (startIndex ..< endIndex))
    }
}
