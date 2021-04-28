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
    public var reads: [String: Bool]?
    @LosslessValue public var pages: UInt = 0
    
    public enum CodingKeys: String, CodingKey {
        case changeToken
        case changeTokenID = "changeIDToken"
        case customFeeds
        case articles
        case reads
        case pages
    }
    
    init (from: [String: Any]) {
        
        guard from.keys.count > 0 else {
            return
        }
        
        changeToken = from["changeToken"] as? String
        changeTokenID = from["changeIDToken"] as? String
        pages = from["pages"] as? UInt ?? 0
        reads = from["reads"] as? [String: Bool]
        
        if let customF = from["customFeeds"] as? [[String: Any]] {
            
            let cf = customF.map { SyncChange.init(feedID: $0["feedID"] as? UInt ?? 0, title: $0["title"] as? String) }
            
            customFeeds = cf
            
        }
        
        if let articles = from["articles"] as? [[String: Any]] {
            
            let a  = articles.map { Article.init(from: $0) }
            
            self.articles = a
            
        }
        
    }
    
}
