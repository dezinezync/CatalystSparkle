//
//  FeedBulkOperation.swift
//  
//
//  Created by Nikhil Nigade on 10/03/21.
//

import Foundation
import Models

public struct FeedBulkOperation: Equatable {
    
    public static func == (lhs: FeedBulkOperation, rhs: FeedBulkOperation) -> Bool {
        return lhs.feed.feedID == rhs.feed.feedID
    }
    
    public let feed: Feed
    public let metadata: FeedMeta
    
    public init(feed: Feed, metadata: FeedMeta) {
        self.feed = feed
        self.metadata = metadata
    }
    
}
