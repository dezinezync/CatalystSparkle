//
//  File.swift
//  
//
//  Created by Nikhil Nigade on 08/03/21.
//

import Foundation

@propertyWrapper
public struct FailableDecodable<Wrapped: Codable>: Codable {
    public var wrappedValue: Wrapped?

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = try? container.decode(Wrapped.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
    
}
