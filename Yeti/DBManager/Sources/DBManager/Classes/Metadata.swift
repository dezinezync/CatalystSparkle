//
//  Metadata.swift
//  
//
//  Created by Nikhil Nigade on 06/03/21.
//

import Foundation

public struct FeedMeta: Codable {
    
    public var id: UInt
    public var url: URL
    public var title: String
    public var folderID: UInt?
    public var localNotifications: Bool = false
    public var readerMode: Bool = false
    
    public init(id: UInt, url: URL, title: String) {
        
        self.id = id
        self.url = url
        self.title = title
        
    }
    
}

public struct ArticleMeta: Codable {
    
    public var read: Bool = true
    public var bookmarked: Bool = false
    public var fulltext: Bool = false
    public var feedID: UInt
    public var timestamp: Double
    public var titleWordCloud: [String]?
    
    public init(feedID: UInt, read: Bool, bookmarked: Bool, fulltext: Bool, timestamp: Date, titleWordCloud: [String]?) {
        
        self.feedID = feedID
        self.read = read
        self.bookmarked = bookmarked
        self.fulltext = fulltext
        self.timestamp = timestamp.timeIntervalSince1970
        self.titleWordCloud = titleWordCloud
        
    }
    
}
