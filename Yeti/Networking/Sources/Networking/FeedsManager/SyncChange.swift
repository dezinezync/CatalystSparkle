//
//  SyncChange.swift
//  
//
//  Created by Nikhil Nigade on 07/03/21.
//

import Foundation

public struct SyncChange: Codable {
    
    public let feedID: UInt
    public let title: String?
    public let order: UInt?
    
    public init(feedID: UInt, title: String?) {
        self.title = title
        self.feedID = feedID
        self.order = 0
    }
    
    public init(feedID: UInt, title: String?, order: UInt?) {
        self.title = title
        self.feedID = feedID
        self.order = order
    }
    
}
