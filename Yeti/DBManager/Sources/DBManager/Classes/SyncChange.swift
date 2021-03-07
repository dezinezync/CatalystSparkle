//
//  SyncChange.swift
//  
//
//  Created by Nikhil Nigade on 07/03/21.
//

import Foundation

struct SyncChange {
    
    var feedID: UInt
    var title: String?
    var order: UInt?
    
    init(feedID: UInt, title: String?) {
        self.title = title
        self.feedID = feedID
    }
    
    init(feedID: UInt, title: String?, order: UInt?) {
        self.title = title
        self.feedID = feedID
        self.order = order
    }
    
}
