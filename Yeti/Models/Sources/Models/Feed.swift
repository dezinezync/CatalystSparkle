//
//  Feed.swift
//  
//
//  Created by Nikhil Nigade on 02/03/21.
//

import Foundation

public let kFeedSafariReaderMode = "com.elytra.feed.safariReaderMode"
public let kFeedLocalNotifications = "com.elytra.feed.localNotifications"

class Feed: NSObject, Codable, ObservableObject {
    
    var feedID: UInt!
    var summary: String!
    var title: String!
    var url: URL!
    var favicon: URL!
    var extra: [String]!
    var rpcCount: UInt!
    var lastRPC: Date!
    
    private enum CodingKeys: String, CodingKey {
        case feedID
        case summary
        case title
        case url
        case favicon
        case extra
        case rpcCount
        case lastRPC
    }
    
    @Published var unread: UInt! = 0
    
    weak var folder: Folder?
    
    convenience init(from dict: [String: Any]) {
        
        self.init()
        
        setValuesForKeys(dict)
        
    }
    
}

extension Feed {
    
    
    
}

extension Feed: Copyable {}
