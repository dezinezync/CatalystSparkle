//
//  Copyable.swift
//  
//
//  Created by Nikhil Nigade on 06/03/21.
//

import Foundation

protocol Copyable {
    func copy() -> Self
}

extension Copyable {
    func copy() -> Self where Self: Codable {
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
