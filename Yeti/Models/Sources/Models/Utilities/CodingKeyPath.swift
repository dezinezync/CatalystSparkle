//
//  File.swift
//  
//
//  Created by Nikhil Nigade on 05/03/21.
//

import Foundation

extension Encodable {
    func hasKey(for path: String) -> Bool {
        return Mirror(reflecting: self).children.contains { $0.label == path }
    }
    func value(for path: String) -> Any? {
        return Mirror(reflecting: self).children.first { $0.label == path }?.value
    }
}

