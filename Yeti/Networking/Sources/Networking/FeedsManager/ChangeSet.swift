//
//  File.swift
//  
//
//  Created by Nikhil Nigade on 07/03/21.
//

import Foundation
import Models
import BetterCodable

public struct ChangeSet: Codable {
    
    public var changeToken: String!
    public var changeTokenID: String!
    public var customFeeds: [SyncChange]?
    public var articles: [Article]?
    public var reads: [Int: Bool]?
    @LosslessValue public var pages: UInt = 0
    
    public enum CodingKeys: String, CodingKey {
        case changeToken
        case changeTokenID = "changeIDToken"
        case customFeeds
        case articles
        case reads
        case pages
    }
    
}
