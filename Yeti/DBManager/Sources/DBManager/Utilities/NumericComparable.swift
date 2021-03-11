//
//  NumericComparable.swift
//  
//
//  Created by Nikhil Nigade on 10/03/21.
//

import Foundation

extension UInt {
    
    public func compare(other: UInt) -> ComparisonResult {
        
        if self == other { return .orderedSame }
        else if self > other { return .orderedDescending }
        else { return .orderedAscending }
        
    }
    
}

extension Double {
    
    public func compare(other: Double) -> ComparisonResult {
        
        if self == other { return .orderedSame }
        else if self > other { return .orderedDescending }
        else { return .orderedAscending }
        
    }
    
}
