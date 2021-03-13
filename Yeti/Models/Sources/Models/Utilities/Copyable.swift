//
//  Copyable.swift
//  
//
//  Created by Nikhil Nigade on 06/03/21.
//

import Foundation

public protocol Copyable {
    func codableCopy() -> Self
}

public extension Copyable {
    func codableCopy () -> Self where Self: Codable {
        do {
            let encoded = try JSONEncoder().encode(self)
            let decoded = try JSONDecoder().decode(Self.self, from: encoded)
            return decoded
        }
        catch {
            fatalError(error.localizedDescription)
        }
    }
}
