//
//  FailableCodable.swift
//  
//
//  Created by Nikhil Nigade on 08/03/21.
//

import Foundation

@propertyWrapper
public struct FailableURL: Codable {
    
    public var wrappedValue: URL?
    
    public init(wrappedValue: URL?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self.wrappedValue = URL(string: str)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        try? wrappedValue?.absoluteString.encode(to: encoder)
    }
    
}

@propertyWrapper
public struct FailableRange: Codable {
    
    public var wrappedValue: NSRange?
    
    public init(wrappedValue: NSRange?) {
        self.wrappedValue = wrappedValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self.wrappedValue = NSRangeFromString(str)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        if let wrappedValue = wrappedValue {
            try? NSStringFromRange(wrappedValue).encode(to: encoder)
        }
    }
    
}
