//
//  File.swift
//  
//
//  Created by Nikhil Nigade on 07/03/21.
//

import Foundation
import Models

public struct ChangeSet: Codable {
    
    public let changeToken: String!
    public let changeTokenID: String!
    public let customFeeds: [SyncChange]?
    public let articles: [Article]?
    public let reads: [Int: Bool]?
    public let pages: UInt
    
}
